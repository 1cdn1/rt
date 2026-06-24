<?php
/**
 * Twenty Twenty-Two functions and definitions
 *
 * @link https://developer.wordpress.org/themes/basics/theme-functions/
 *
 * @package WordPress
 * @subpackage Twenty_Twenty_Two
 * @since Twenty Twenty-Two 1.0
 */


if ( ! function_exists( 'twentytwentytwo_support' ) ) :

	/**
	 * Sets up theme defaults and registers support for various WordPress features.
	 *
	 * @since Twenty Twenty-Two 1.0
	 *
	 * @return void
	 */
	function twentytwentytwo_support() {

		// Add support for block styles.
		add_theme_support( 'wp-block-styles' );

		// Enqueue editor styles.
		add_editor_style( 'style.css' );

	}

endif;

add_action( 'after_setup_theme', 'twentytwentytwo_support' );

if ( ! function_exists( 'twentytwentytwo_styles' ) ) :

	/**
	 * Enqueue styles.
	 *
	 * @since Twenty Twenty-Two 1.0
	 *
	 * @return void
	 */
	function twentytwentytwo_styles() {
		// Register theme stylesheet.
		$theme_version = wp_get_theme()->get( 'Version' );

		$version_string = is_string( $theme_version ) ? $theme_version : false;
		wp_register_style(
			'twentytwentytwo-style',
			get_template_directory_uri() . '/style.css',
			array(),
			$version_string
		);

		// Enqueue theme stylesheet.
		wp_enqueue_style( 'twentytwentytwo-style' );

	}

endif;

add_action( 'wp_enqueue_scripts', 'twentytwentytwo_styles' );

// Add block patterns
require get_template_directory() . '/inc/block-patterns.php';


function creator_scripts() {
    if(basename(get_page_template()) == 'creater.php'){
       // wp_enqueue_style('style9', 'https://www.mtgcardbuilder.com/css/style-10.css?v='.uniqid());

    }

}

add_action('wp_enqueue_scripts', 'creator_scripts',99);


// function that runs when shortcode is called
function creator_shortcode() { 
	if(is_user_logged_in()){
		$current_user = wp_get_current_user();
        $email= $current_user->user_email;
        $username=$current_user->display_name ;
   
require_once(get_template_directory() . '/creater.php');
}else{
	// wp_redirect( get_site_url().'/login?redirect_to=https%3A%2F%2Fmtgcardbuilder.com%2Fwp%2Fcreator%2F&reauth=1' ); 
    echo "<script>
    window.location = 'https://mtgcardbuilder.com/login?redirect_to=https%3A%2F%2Fmtgcardbuilder.com%2Fwp%2Fcreator%2F&reauth=1';
</script>";
    die();
}
$message="";
  
// Things that you want to do.
  
// Output needs to be return
return $message;
}
function phyrexian_shortcode() { 
require_once(get_template_directory() . '/phyrexian.php');
$message="";
  
// Things that you want to do.
  
// Output needs to be return
return $message;
}
function print_shortcode() { 
require_once(get_template_directory() . '/print.php');
$message="";
  
// Things that you want to do.
  
// Output needs to be return
return $message;
}
function creator_shortcode_admin() { 
     $current_user= wp_get_current_user();
if (true || user_can( $current_user, 'administrator' )) {
require_once(get_template_directory() . '/creater-test.php');
}


$message="";
  
// Things that you want to do.
  
// Output needs to be return
return $message;
}
function public_profile() { 
require_once(get_template_directory() . '/public-profile.php');
return;
}
function dynamic_homepage() { 
global $wpdb;
$dynamic=json_decode(file_get_contents(ABSPATH."cronFiles/dynamicGallery.json"),true);
$designed=0;
$gallery=0;
$recentCards=array();
if(is_array($dynamic)){
    $designed=$dynamic['designed'];
    $gallery=$dynamic['gallery'];
    $recentCards=$dynamic['recentCards'];
}
$user_query = new WP_User_Query( array( 'role__in' => array( 'Subscriber', 'Customer' ) ) );
$users=$user_query->get_total();
echo '<script>

document.addEventListener("DOMContentLoaded", function(event) {
    console.log(jQuery("#card-designed").find(".number-percentage").attr("data-value"))
    jQuery("#card-designed").find("h2").text("'.$designed.'+")
    jQuery("#cards-in-gallery").find("h2").text("'.$gallery.'+")
    jQuery("#active-designers").find("h2").text("'.$users.'+")
    var imgUrls = JSON.parse(\''. json_encode($recentCards) .'\');
    
    jQuery("#recent-gallery-cards").find(".elementor-image-carousel").find(".swiper-slide").each(function(i, obj) {
        const srcc=imgUrls[i].image_url;
        let cont=0;
        jQuery(obj).find("img.swiper-slide-image").on("load",function(){
            if(cont>0){
                jQuery(obj).find("img.swiper-slide-image").off("load")
                return;
            }
            cont++;
            jQuery(obj).find("img.swiper-slide-image").attr("src",srcc)
            jQuery(obj).find("img.swiper-slide-image").attr("loading","lazy")
            })
            
            
        })
        jQuery("#recent-gallery-cards").find(".elementor-image-carousel").find(".swiper-slide").each(function(i, obj) {
        jQuery(obj).find("img.swiper-slide-image").addClass("lightbox-trigger")
        })
})


// Add click event listener to all images with class "lightbox-trigger"
jQuery(document).on("click", ".lightbox-trigger",function() {
    jQuery("#lightbox").css({"display":"flex"})

    // Show lightbox
    // Set image source
    jQuery("#lightbox-image").attr("src",jQuery(this).attr("src"))
});
 jQuery(document).ready(function(){
        jQuery(\'#aswift_1\').load(function(){
           console.log("loaded")
        });
    });
 jQuery(\'#previewCanvas\').bind("contextmenu",function(e){
        return false;
    });

jQuery(document).on("click", "#close-btn",function() {
    jQuery("#lightbox").css({"display":"none"})
    jQuery("#lightbox-image").attr("src","#")
})
jQuery(document).on("click", "#lightbox",function() {
    jQuery("#lightbox").css({"display":"none"})
    jQuery("#lightbox-image").attr("src","#")
})
jQuery("body").prepend(` <div id="lightbox">
  <div id="lightbox-content">
    <img id="lightbox-image" src="#" alt="lightbox image">
    <span id="close-btn">&times;</span>
  </div>
</div> `)
</script>


';
}
// register shortcode
function show_ads_shortcode(){
    $show=true;
    if(is_user_logged_in()){
        $sub=CheckStatusSub(get_current_user_id());
        if(is_array($sub) AND ($sub['status'] == 'active' )){
            $show=false;
        }
    }
    if($show == true){
        return '<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-2481066081199771"
     crossorigin="anonymous"></script>
<!-- download image -->
                        <a href="https://www.printingproxies.com/?ref=1" target="_blank"><ins class="adsbygoogle"
                             style="display:block"
                             data-ad-client="ca-pub-2481066081199771"
                             data-ad-slot="1624659978"
                             data-ad-format="auto"
                             data-full-width-responsive="true"></ins></a>
                        <script>
                        function sleep(ms) {
                                return new Promise(resolve => setTimeout(resolve, ms));
                            }
                             (adsbygoogle = window.adsbygoogle || []).push({});
                        async function checkAd(){
                            await sleep(5000);
                            
                            }
                        
                        </script>
                        <style type="text/css">
                            .adsbygoogle{
                                text-align: center;
                            }
                            #aswift_1_host{
                                
                                background-repeat: no-repeat;
                                background-position-x: center;
                                background-size: contain;
                            }
                            #aswift_2_host,.pp-add{
                                
                                    background-repeat: no-repeat;
                                    background-position-x: center;
                                    background-size: contain;
                            }
                            .adsbygoogle[data-ad-status="unfilled"],.pp-add{
                                background-image: url('.get_site_url().'/img/BANNER_pp.png) !important;
                                    background-repeat: no-repeat;
                                    background-position-x: center;
                                    background-size: contain;
                                        background-position-y: center;
                            }
                        </style>
                        
                        ';
    }
}
add_shortcode('show_ads', 'show_ads_shortcode');
add_shortcode('creator', 'creator_shortcode');
add_shortcode('phyrexian', 'phyrexian_shortcode');
add_shortcode('print', 'print_shortcode');
add_shortcode('creator_admin', 'creator_shortcode_admin');
add_shortcode('public_profile', 'public_profile');
add_shortcode('dynamic-homepage', 'dynamic_homepage');
function mtg_gallery_shortcode() { 
// 	if(is_user_logged_in()){
// 		$current_user = wp_get_current_user();
//         $email= $current_user->user_email;
   
// }else{
//     echo "<script>
//     window.location = 'https://mtgcardbuilder.com/login?redirect_to=https%3A%2F%2Fmtgcardbuilder.com%2Fwp%2Fmtg-custom-card-gallery%2F&reauth=1';
// </script>";
//     die();
// }
	$message="";
require_once(get_template_directory() . '/gallery.php');
  
// Things that you want to do.
  
// Output needs to be return
return $message;
}
// register shortcode
add_shortcode('mtg_gallery', 'mtg_gallery_shortcode');
add_shortcode('mtg_saved', 'mtg_saved_shortcode');
function mtg_saved_shortcode() { 
   
        $message="";
    require_once(get_template_directory() . '/savedCards.php');
      
  
    return $message;
    }

function mtg_gallery_accept_shortcode() { 
 $current_user= wp_get_current_user();
if (user_can( $current_user, 'administrator' ) OR user_can( $current_user, 'moderator' )) {
    require_once(get_template_directory() . '/gallery_accept.php');
}else{
    wp_redirect( get_site_url().'/login' );
}

    $message="";
  
// Things that you want to do.
  
// Output needs to be return
return $message;
}
// register shortcode
add_shortcode('mtg_gallery_accept', 'mtg_gallery_accept_shortcode');
function mtg_user_dashboard_shortcode() { 
 
if (is_user_logged_in()) {
    require_once(get_template_directory() . '/user_dashboard.php');
}else{
    wp_redirect( get_site_url().'/login' );
}

    $message="";
  
// Things that you want to do.
  
// Output needs to be return
return $message;
}
// register shortcode
add_shortcode('mtg_user_dashboard', 'mtg_user_dashboard_shortcode');





function js_creator_enqueue_scripts() {
    $current_user= wp_get_current_user();
                // if (user_can( $current_user, 'administrator' )) {
                //     wp_enqueue_script ("my-ajax-creator", get_stylesheet_directory_uri() . "/js/creatorTest.js", array('jquery')); 
                // }else{
                    wp_enqueue_script ("my-ajax-creator", get_stylesheet_directory_uri() . "/js/creator.js", array('jquery')); 
                // }
    
    //the_ajax_script will use to print admin-ajaxurl in custom ajax.js
    wp_localize_script('my-ajax-creator', 'the_ajax_script', array('ajaxurl' =>admin_url('admin-ajax.php'),"site_url"=>get_template_directory_uri()));
    if(get_the_ID() == 1385){
        wp_enqueue_script ("my-ajax-creator-admin", get_stylesheet_directory_uri() . "/js/creator-admin.js", array('jquery')); 
        //the_ajax_script will use to print admin-ajaxurl in custom ajax.js
        wp_localize_script('my-ajax-creator-admin', 'the_ajax_script', array('ajaxurl' =>admin_url('admin-ajax.php'),"site_url"=>get_template_directory_uri()));
    }
    

    
    $arrVirtualPath=array('Libs'=>"https://www.printingproxies.com/wp-content/plugins/card-demo/libs/",'TemplateJs'=>"https://www.printingproxies.com/wp-content/plugins/card-demo/front/templates/js/");
     wp_register_script('jQueryUI', $arrVirtualPath['Libs'].'jquery-ui-1.12.0/jquery-ui.min.js', array('jquery'), true);
        wp_enqueue_script('jQueryUI');
         wp_register_script('autocompleteJs', $arrVirtualPath['TemplateJs'].'autocomplete.js?v=2', array('jquery'), true);
         wp_enqueue_script('autocompleteJs');
        wp_register_style('jQueryUICss', $arrVirtualPath['Libs'].'jquery-ui-1.12.0/jquery-ui.min.css', false,'5.9','all');;
        wp_enqueue_style('jQueryUICss');
} 
add_action("wp_enqueue_scripts", "js_creator_enqueue_scripts");
function builder_ajax() {
    require_once __DIR__."/builderAjax.php";
}
add_action('wp_ajax_nopriv_builder_ajax', 'builder_ajax');
add_action('wp_ajax_builder_ajax', 'builder_ajax');
 add_filter( 'user_registration_login_redirect', 'ur_redirect_back', 10, 2 );
 function ur_redirect_back( $redirect_url, $user ) {
    $current_user = (object) $user;
    $roles        = isset( $current_user->roles ) ? (array) $current_user->roles : array();
    if ( in_array( 'administrator', $roles, true ) ) {
        $redirect_url = get_site_url().'/user-dashboard';
    } elseif ( in_array( 'customer', $roles, true ) ) {
        $redirect_url = get_site_url().'/user-dashboard';
    }
    return $redirect_url;
}

// Hook to wordpress before load and check if correct user is on page
add_action( 'wp', 'mtgcardbuilder_is_correct_user' );
function mtgcardbuilder_is_correct_user()
{
    global $post;


    // Not working on homepage
    // Redirect to homepage if wrong user
    if(!empty($post->ID) AND $post->ID == 224 AND is_user_logged_in()) {
      wp_redirect( get_site_url().'/creator' );
      exit;
    }   
    if(!empty($post->ID) AND $post->ID == 230 AND is_user_logged_in()) {
      wp_redirect( get_site_url().'/creator' );
      exit;
    }   
    if(!empty($post->ID) AND $post->ID == 14 AND !is_user_logged_in()) {
      wp_redirect( get_site_url().'/login' );
      exit;
    } 
    if(!empty($post->ID) AND $post->ID == 13 AND !is_user_logged_in()) {
      wp_redirect( get_site_url().'/login?redirect_to=https%3A%2F%2Fmtgcardbuilder.com%2Fcheckout%2F' );
      exit;
    }  

}
add_action('template_redirect','check_if_logged_in');
function check_if_logged_in()
{
    $pageid = get_option( 'woocommerce_checkout_page_id' );
   if(!is_user_logged_in() && is_page($pageid))
    {
        $url = add_query_arg(
            'redirect_to',
            get_permalink($pagid),
            site_url('/my-account/') // your my acount url
        );
        wp_redirect($url);
        exit;
    }
}
function checkMemberpressSub($user_id){
    $mepr_user = new MeprUser($user_id);

    if ($mepr_user->is_active()) {
    // Subscription is active
    return true;
    }
    return false;
}
function CheckStatusSub( $user_id) {
    if($user_id == 1){
        // $user_id=18826;
        
    }
    if(checkMemberpressSub($user_id)){
        return ["status"=>"active", "product_id"=>'prod', "product_name"=>'name'];
    }

   
    
        
    $product_id=530;
    $product_id2=7388;
  $subscriptions = get_posts([ 
    "numberposts" => -1,
    "post_type" => "ywsbs_subscription", // Subscription post type
    "orderby" => "post_date", 
    "order" => "ASC",
    "meta_query" => [ // Meta query
    [
      "key" => "product_id", // Product ID
      "value" => array($product_id,$product_id2),
      "compare" => "IN",
    ],
    [
      "key" => "user_id", // User ID
      "value" => $user_id,
      "compare" => "=",
    ],
    [
      "key" => "start_date", // Subscription start date filter
      "value" => time(),
      "compare" => "<",
    ],
    [
      "key" => "payment_due_date", // Subscription due date filter
      "value" => time() - (2 * 24 * 60 * 60), // Add 2 days before expire
      "compare" => ">",
    ],
    [
      "key" => "status", // Subscription status filter
      "value" => "active", 
      "compare" => "=",
    ],
    ]
  ]);
     
  if(count($subscriptions)>0){
    // Active subscription found
    return ["status"=>"active", "product_id"=>$product_id, "product_name"=>get_post_meta($subscriptions[0]->ID, "product_name",true)];
  }else{
    $manSub=get_user_meta($user_id,"_manual_sub",true);
        if(!empty($manSub)){
            $current=time();
            $to=$manSub;
            if(is_int((int)$to) AND $current<$to){
                return ["status"=>"active", "product_id"=>-1, "product_name"=>"manual sub"];
            }
        }
    // No active subscription found
    return  ["status"=>"expired", "product_id"=>$product_id];
  }
} 
    

add_filter( 'woocommerce_account_menu_items', 'misha_remove_my_account_links' );
function misha_remove_my_account_links( $menu_links ){
    unset( $menu_links[ 'edit-address' ] ); // Addresses
    
    //unset( $menu_links[ 'dashboard' ] ); // Remove Dashboard
    unset( $menu_links[ 'payment-methods' ] ); // Remove Payment Methods
    unset( $menu_links[ 'orders' ] ); // Remove Orders
    unset( $menu_links[ 'downloads' ] ); // Disable Downloads
    unset( $menu_links[ 'ppcp-paypal-payment-tokens' ] ); // Disable Downloads
    //unset( $menu_links[ 'edit-account' ] ); // Remove Account details tab
    //unset( $menu_links[ 'customer-logout' ] ); // Remove Logout link
    
    return $menu_links;
    
}

// Add the custom field "nickname"
add_action( 'woocommerce_edit_account_form', 'add_nickname_to_edit_account_form' );
function add_nickname_to_edit_account_form($account_fields) {
    $user = wp_get_current_user();
    ?>
        <p class="woocommerce-form-row woocommerce-form-row--wide form-row form-row-wide">
        <label for="nickname"><?php _e( 'Nickname', 'woocommerce' ); ?></label>
        <input type="text" class="woocommerce-Input woocommerce-Input--text input-text" name="nickname" id="nickname" value="<?php echo esc_attr( get_user_meta($user->ID,'nickname',true)); ?>" />

        <!-- adding profile image -->
    </p>
    <?php
}

// Save the custom field 'nickname' 
add_action( 'woocommerce_save_account_details', 'save_nickname_account_details', 12, 1 );
function save_nickname_account_details( $user_id ) {
    // For Favorite color
    if( isset( $_POST['nickname'] ) )
        update_user_meta( $user_id, 'nickname', sanitize_text_field( $_POST['nickname'] ) );

  
}


add_filter ( 'woocommerce_account_menu_items', 'mtgbuilder_my_profile', 40 );
function mtgbuilder_my_profile( $menu_links ){
    
    $menu_links = array_slice( $menu_links, 0, 3, true ) 
    + array( 'public-profile' => 'Update Public Profile' )
    + array_slice( $menu_links, 3, NULL, true );

    $menu_links = array_slice( $menu_links, 0, 3, true ) 
    + array( 'my-profile' => 'My Profile' )
    + array_slice( $menu_links, 3, NULL, true );
    
    return $menu_links;

}
add_action( 'init', 'mtgbuilder_add_endpoint' );
function mtgbuilder_add_endpoint() {

    add_rewrite_endpoint( 'public-profile', EP_PAGES );

}
// content for the new page in My Account, woocommerce_account_{ENDPOINT NAME}_endpoint
add_action( 'woocommerce_account_public-profile_endpoint', 'mtgbuilder_my_account_profile_endpoint_content' );
function mtgbuilder_my_account_profile_endpoint_content() {
       require_once(get_template_directory() . '/profile.php');
    // of course you can print dynamic content here, one of the most useful functions here is get_current_user_id()
    

}


// add_filter('woocommerce_get_endpoint_url', 'woocommerce_hacks_endpoint_url_filter', 10, 4);
//     function woocommerce_hacks_endpoint_url_filter($url, $endpoint, $value, $permalink) {
//         $downloads = get_option('woocommerce_myaccount_downloads_endpoint', 'downloads');
//         if (empty($downloads) == false) {
//             if ($endpoint == $downloads) {
//                 $url = '//example.com/customer-area/dashboard';
//             }
//         }
//         return $url;
//     }

add_theme_support( 'menus' );

function my_wp_nav_menu_args( $args = '' ) {
if( is_user_logged_in() ) {
// Logged in menu to display
$args['menu'] = 30;
 
} else {
// Non-logged-in menu to display
$args['menu'] = 29;
}
return $args;
}
add_filter( 'wp_nav_menu_args', 'my_wp_nav_menu_args' );



// function modify_home_in_nav_menu_objects( $items, $args ) {
//     foreach ( $items as $k => $object ) {
//         // you can also target given page using this if:
//         // if ( 'page' == $object->object && 2 == $object->object_id ) {
//         if ( 1281 == $object->ID ) {
//             $object->url="https://mtgcardbuilder.com/public-profile?userid=".get_current_user_id();
//         }
//     }
//     return $items;
// }


//Disable the new user notification sent to the site admin
function smartwp_disable_new_user_notifications() {
 //Remove original use created emails
 remove_action( 'register_new_user', 'wp_send_new_user_notifications' );
 remove_action( 'edit_user_created_user', 'wp_send_new_user_notifications', 10, 2 );
 
 //Add new function to take over email creation
 add_action( 'register_new_user', 'smartwp_send_new_user_notifications' );
 add_action( 'edit_user_created_user', 'smartwp_send_new_user_notifications', 10, 2 );
}
function smartwp_send_new_user_notifications( $user_id, $notify = 'user' ) {
 if ( empty($notify) || $notify == 'admin' ) {
 return;
 }elseif( $notify == 'both' ){
 //Only send the new user their email, not the admin
 $notify = 'user';
 }
 wp_send_new_user_notifications( $user_id, $notify );
}
add_action( 'init', 'smartwp_disable_new_user_notifications' );


//adding roles
add_role('moderator', __(
   'Moderator'),
   array()
);

// function pp_check_user_display_updated($done, $user_id, $meta_key, $meta_value){
//     if($meta_key == "nickname"){
//         $new_nick=$meta_value;
//         global $wpdb;
//         $wpdb->update("cards_visuals",array("user_name"=>$new_nick),array("user_id"=>$user_id));

//     }

// }
// add_action( 'update_user_metadata', 'pp_check_user_display_updated',10,4 );

// add_action( 'wp_print_styles',     'my_deregister_styles', 100 );

add_filter( 'auth_cookie_expiration', 'extend_login_cookie' );

function extend_login_cookie( $expirein ) {
    return 31556926; // 1 year in seconds (Adjust to your needs)
}

add_filter('woocommerce_available_payment_gateways', 'unsetting_payment_gateway', 10, 1);
function unsetting_payment_gateway( $available_gateways ) {
    // Not in backend (admin)
   $current_user= wp_get_current_user();
                if (user_can( $current_user, 'administrator' )) {
                    return $available_gateways;
                }
       

    // HERE Define the limit of quantity item
    
        // HERE set the slug of your payment method
        unset($available_gateways['cod']);
     
 
    return $available_gateways;
}

add_action('woocommerce_payment_complete', 'makeOrderInPP', 10, 1);

function makeOrderInPP( $order_id ) {
    $orderGet=wc_get_order($order_id);
    $order=$orderGet->get_data();
    $items = $orderGet->get_items();
    $cardData=array();
    $prods=array();
    foreach ( $items as $item_id => $item ) {
        $product_id = $item->get_variation_id() ? $item->get_variation_id() : $item->get_product_id();
        $prods[]=array("name"=>$item->get_name(),"id"=>$product_id,"qty"=>$item->get_quantity(),"price"=>$item->get_product()->get_price());
        
    }
    $order['cardsData']=array();
    $order['prods']=$prods;
    $order['site']='mtgcardbuilder';
    $order['is_a_renew']=get_post_meta($order_id,"is_a_renew",true);
    
    $curl = curl_init();
    file_put_contents(ABSPATH."filename2",json_encode($order));

curl_setopt_array($curl, array(
  CURLOPT_URL => 'https://www.printingproxies.com/wp-content/plugins/card-demo/webhook/subscription/subscription.php?run=1',
  CURLOPT_RETURNTRANSFER => true,
  CURLOPT_ENCODING => '',
  CURLOPT_MAXREDIRS => 10,
  CURLOPT_TIMEOUT => 300,
  CURLOPT_FOLLOWLOCATION => true,
  CURLOPT_CONNECTTIMEOUT => 100,
  CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
  CURLOPT_CUSTOMREQUEST => 'POST',
  CURLOPT_POSTFIELDS =>json_encode($order),
  CURLOPT_HTTPHEADER => array(
    'Content-Type: application/json',
    'Cookie: PHPSESSID=18c58fc1083823571f0d4e81f1d8da35'
  ),
));

    $response = curl_exec($curl);
    $response=json_decode($response,true);
    if(is_array($response) && !empty($response['success'])){
        add_post_meta($order_id,'parentId',$response['success'],true);
    }else{
    }
    

    curl_close($curl);

}

add_filter( 'wp_mail', function ( $args ) {
    // Check the email subject to identify the redundant email
    if ( isset( $args['subject'] ) && strpos( $args['subject'], 'Activate your account on https://mtgcardbuilder.com' ) !== false ) {
        file_put_contents(ABSPATH."wp_mail.txt",json_encode($args));
    // Prevent this email from being sent
        $args['to'] = [];
    }elseif ( isset( $args['subject'] ) && strpos( $args['subject'], 'New User Registration on https://mtgcardbuilder.com' ) !== false ) {
        file_put_contents(ABSPATH."wp_mail2.txt",json_encode($args));
    // Prevent this email from being sent
        $args['to'] = [];
    }
    return $args;
});


add_filter('woocommerce_billing_fields', function($fields) {
    $fields['billing_phone']['required'] = false;
    return $fields;
});
//since we have two subs yhith and memeberpress. if the page is yith my-subscrpition than redirect to memberpress one if memberpress sub  is actrive

// function redirect_yith_subs_to_memberpress() {
//     if ( !is_user_logged_in() ) return;

//     // Get current path
//     $current_path = trim($_SERVER['REQUEST_URI'], '/');

//     // Adjust if your site is in a subdirectory
//     $expected_path = 'my-account/my-subscription';

//     // Basic match (you can improve this to handle query strings)
//     if ( strpos($current_path, $expected_path) !== false ) {
//         if ( function_exists('checkMemberpressSub') && checkMemberpressSub(get_current_user_id()) ) {
//     wp_redirect(site_url('/account-page'));
//             exit;
//         }
//     }
// }
// add_action('wp', 'redirect_yith_subs_to_memberpress');

add_action('template_redirect', function() {
    if (is_page('my-account') && is_user_logged_in()) {
        global $wpdb;
        $user_id = get_current_user_id();

        // Adjust if your table prefix is not 'wp_'
        $table = $wpdb->prefix . 'mepr_subscriptions';

        $has_subscription = $wpdb->get_var(
            $wpdb->prepare(
                "SELECT id FROM $table WHERE user_id = %d LIMIT 1",
                $user_id
            )
        );

        if ($has_subscription) {
            // wp_redirect(site_url('/account-page/'));
            // exit;
            add_action('wp_footer', function() {
            ?>
            <script>
            jQuery(document).ready(function($) {
                console.log("herer");
                // Wait for the DOM to be fully loaded
                if (jQuery('.ywsbs-item').length <= 0) {
                    window.location.href = '<?php echo site_url('/account/?action=subscriptions'); ?>';
                }
                // if (jQuery('.ywsbs-my-subscriptions').length > 0) {
                //     window.location.href = '<?php// echo site_url('/account/?action=subscriptions'); ?>';
                // }
            });
            </script>
            <?php
        });
        }
    }
});
add_action('template_redirect', function() {
    if (is_cart()) {
        wp_redirect(site_url('/mtg-card-builder-premium-account/'));
        exit;
    }
});


function custom_login_notice() {
    // Only show on the login form (not register or lost password)
    if (isset($_GET['action']) && $_GET['action'] !== 'login') {
        return;
    }

    // Display notice
    echo '<div style="border: 2px solid #d63638; background: #fbeaea; padding: 10px; margin-bottom: 20px;">
        <strong>Login on this page is disabled.</strong> Please use our <a href="/login">Login page</a> instead.
    </div>';

    // JavaScript: check for body.login and #login before redirecting. if else is to redirect fast else redirect no matter what
    echo '<script>
    (function redirectIfReady() {
        if (document.body && document.body.classList.contains("login") && document.getElementById("login")) {
            window.location.href = "/login";
        } else {
            document.addEventListener("DOMContentLoaded", function() {
                if (document.body.classList.contains("login") && document.getElementById("login")) {
                    window.location.href = "/login";
                }
            });
        }
    })();
</script>';
}
add_action('login_message', 'custom_login_notice');




// --permission code

add_filter( 'user_has_cap', function( $allcaps, $caps, $args, $user ) {
    // Only for this specific user
    if ( ! $user || (int) $user->ID !== 109991 ) {
        return $allcaps;
    }

    // Only in admin area
    if ( ! is_admin() ) {
        return $allcaps;
    }

    $page = isset($_GET['page']) ? sanitize_text_field($_GET['page']) : '';
    $path = isset($_GET['path']) ? sanitize_text_field($_GET['path']) : '';

    // Target URL:
    // /wp-admin/admin.php?page=wc-admin&path=%2Fpayments%2Fdisputes&filter=awaiting_response
    if ( $page === 'wc-admin' && strpos( $path, '/payments/disputes' ) === 0 ) {
        // Temporarily grant reports capability for this request only
        $allcaps['view_woocommerce_reports'] = true;
    }

    return $allcaps;
}, 10, 4 );
add_filter( 'user_has_cap', function( $allcaps, $caps, $args, $user ) {
    // Only target this user
    if ( ! $user || (int) $user->ID !== 109991 ) {
        return $allcaps;
    }

    if ( ! is_admin() ) {
        return $allcaps;
    }

    $page = isset($_GET['page']) ? sanitize_text_field($_GET['page']) : '';
    $path = isset($_GET['path']) ? sanitize_text_field($_GET['path']) : '';

    // Block Payments → Overview
    // URL: admin.php?page=wc-admin&path=/payments/overview
    file_put_contents(ABSPATH."/payment.txt",$path);
    if ( $page === 'wc-admin' && (strpos( $path, '/payments/overview' ) || strpos( $path, '/payments/deposits' )) === 0 ) {
        unset( $allcaps['manage_woocommerce'] );
    }

    return $allcaps;
}, 20, 4 );


add_filter( 'user_has_cap', function( $allcaps, $caps, $args, $user ) {
    // Only target user ID 109991
    if ( ! $user || (int) $user->ID !== 109991 ) {
        return $allcaps;
    }

    // Only affect wp-admin requests
    if ( ! is_admin() ) {
        return $allcaps;
    }

    $page      = isset($_GET['page']) ? sanitize_text_field($_GET['page']) : '';
    $post_type = isset($_GET['post_type']) ? sanitize_text_field($_GET['post_type']) : '';
    $tab       = isset($_GET['tab']) ? sanitize_text_field($_GET['tab']) : '';

    // --- BLOCK WOOCOMMERCE SETTINGS PAGE ---
    // URL: admin.php?page=wc-settings
    if ( $page === 'wc-settings' ) {
        unset( $allcaps['manage_woocommerce'] );
        return $allcaps;
    }

    // --- BLOCK YITH AFFILIATE PANEL ---
    // URL: admin.php?page=yith_wcaf_panel
    if ( $page === 'yith_wcaf_panel' ) {
        unset( $allcaps['manage_woocommerce'] );
        return $allcaps;
    }

    // --- BLOCK WOOCOMMERCE ORDERS & PRODUCTS LIST (and singles) ---
    // URLs: edit.php?post_type=shop_order / edit.php?post_type=product
    if (  $post_type === 'product' ) {
        unset( $allcaps['manage_woocommerce'] );
        return $allcaps;
    }

    return $allcaps;
}, 10, 4 );
//this code is to stop overview ajax
add_action('admin_enqueue_scripts', function () {
    if ( ! is_admin() ) return;
    if ( get_current_user_id() !== 109991 ) return;

    $page = $_GET['page'] ?? '';
    if ( $page !== 'wc-admin' ) return;

    wp_register_script('pp_wcadmin_guard_debug', '', [], null, true);
    wp_enqueue_script('pp_wcadmin_guard_debug');

    $js = <<<'JS'
(function () {
  console.log('[PP WCADMIN GUARD] script loaded');

  // === DEBUG BANNER ===
  const banner = document.createElement('div');
  banner.style.cssText = `
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    background: red;
    color: white;
    font-size: 14px;
    padding: 6px 10px;
    z-index: 999999;
    text-align: center;
  `;
  banner.textContent = 'PP WC-ADMIN GUARD ACTIVE';
//   document.body.appendChild(banner);

  function getPath() {
    const params = new URLSearchParams(window.location.search);
    return params.get('path') || '';
  }

  function logState(src) {
    console.log('[PP GUARD]', src, {
      url: location.href,
      path: getPath()
    });
  }

  function hardRedirect() {
    window.location.href = 'admin.php?page=wc-admin&path=%2Fpayments%2Fdisputes';
  }

  function guard(source) {
    const path = getPath();
    logState(source);

    if (path.startsWith('/payments/overview')) {
      hardRedirect();
    }
  }

  // Initial load
  guard('initial-load');

  // Hook SPA routing
  const _pushState = history.pushState;
  history.pushState = function () {
    _pushState.apply(this, arguments);
    guard('pushState');
  };

  const _replaceState = history.replaceState;
  history.replaceState = function () {
    _replaceState.apply(this, arguments);
    guard('replaceState');
  };

  window.addEventListener('popstate', function () {
    guard('popstate');
  });

  // Intercept clicks early
  document.addEventListener('click', function (e) {
    const a = e.target.closest && e.target.closest('a');
    if (!a || !a.href) return;

    if (
      a.href.includes('page=wc-admin') &&
      (a.href.includes('/payments/overview') || a.href.includes('%2Fpayments%2Foverview'))
    ) {
    //   console.warn('[PP GUARD] CLICK BLOCKED', a.href);
    //   alert('CLICK BLOCKED: Payments Overview');
      e.preventDefault();
      e.stopPropagation();
      hardRedirect();
    }
  }, true);

})();
JS;

    wp_add_inline_script('pp_wcadmin_guard_debug', $js);
}, 999);

// -- permision code end


// inventory handle
add_action('woocommerce_order_status_completed', function ($order_id) {

    // Load handler file (child theme first, then parent theme)
    $file = get_stylesheet_directory() . '/templates/inventory_order_completed.php';
    if (!file_exists($file)) {
        $file = get_template_directory() . '/templates/inventory_order_completed.php';
    }

    if (file_exists($file)) {
        require_once $file;

        // Call the handler from the required file
        if (function_exists('inv_handle_order_completed')) {
            inv_handle_order_completed($order_id);
        }
    }

}, 20, 1);

//disable plugin update emails
add_filter( 'auto_core_update_send_email', '__return_false' );
add_filter( 'auto_plugin_update_send_email', '__return_false' );
add_filter( 'auto_theme_update_send_email', '__return_false' );
