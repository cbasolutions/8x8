<?php
	function debug($mixed = null, $line = null) {
		/*
			function to display debug information in a human readable format on the screen 
		*/
		echo '<pre>';
		echo 'line called from was '.$line; var_dump($mixed);
		echo '</pre>';
		return null;
	}
	function GetToken($config){
		/*
			Pass in the API key, username and password, a cURL call is made to get the token. 
			If successful the token is returned with associated data in PHP Array format
			If Debug is passed in as TRUE, an output of all variables is displayed
			Required Arguments in the config array:
				username
				password
				8x8-apikey

			Optional Arguments in the config array:
				debug

			action: POST
			arguments: username password
				Example: "username=hugotestpbx.1012&password=Pass1234!" header option: "8x8-apikey: <8x8_apikey>"

			URL:
				https://8x8gateway-prod.apigee.net/analytics/v1/oauth/token

			Returns:
				access_token (string): The access token used for 8x8 API calls. 
				expires_in (integer): The number of seconds the token is valid for. 
				token_type (string): The token type that is returned.

				array (size=3) --Results of the function
					"success" => boolean true/false
					"error" => -- List of any issues within the function, including missing required parameters
						 array (size=1)
							 0 => string "8x8-apikey is missing" (length=21)
					"results" =>
						array (size=3) -- Results of the API call
							"access_token" => string "eyJhbGciOiJSUzI1NiJ9.eyJzdW....icPOwSL6wE3" (length=740)
							"token_type" => string "bearer" (length=6) 
							"expires_in" => int 1800
		*/

		$return = array();
		$return["success"] = true;
	
		//check for required
		if (!array_key_exists("8x8-apikey",$config["voa"])){
			$return["success"] = false;
			$return["error"][] = "8x8-apikey is missing";
		}
	
		if (!array_key_exists("username",$config["voa"])){ 
			$return["success"] = false;
			$return["error"][] = "username is missing";
		}

		if (!array_key_exists("password",$config["voa"])){
			 $return["success"] = false;
			 $return["error"][] = "password is missing";
		}
	 
		if($return["success"] == true){
		
		//set up cURL
		$url = "https://8x8gateway-prod.apigee.net/analytics/".$config["voa"]["version"]."/oauth/token";
		$header = [
		  "8x8-apikey: ".$config["voa"]["8x8-apikey"]
		];
		$post = "username=".$config["voa"]["username"]."&password=".$config["voa"]["password"];
		
		//Start cURL
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, $url);
		curl_setopt($ch, CURLOPT_CONNECTTIMEOUT ,30);
		curl_setopt($ch, CURLOPT_TIMEOUT, 400); //timeout in seconds
		curl_setopt($ch, CURLOPT_VERBOSE, false);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
		curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
		curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_ANY);
		
		//posting
		curl_setopt($ch, CURLOPT_POST, true);
		curl_setopt($ch, CURLOPT_POSTFIELDS, $post);

		//custom header data
		curl_setopt($ch, CURLOPT_HTTPHEADER, $header);
		
		//execute curl
		$data = curl_exec($ch);
		$status_code = curl_getinfo($ch, CURLINFO_HTTP_CODE); //get status code
		$curl_errno = curl_errno($ch);
		$curl_error = curl_error($ch);
		curl_close($ch);
		
		//convert to Array
		$tokenArray = json_decode($data, true);
		$return["results"] = $tokenArray;
	}
	
	//show debug if requested
	if (array_key_exists("debug",$config["voa"]) && $config["voa"]["debug"] == true){
		debug($config["voa"], __LINE__ ." Config|VOA : ");
		debug($url, __LINE__ ." URL: ");
		debug($header, __LINE__ ." header: ");
		debug($post, __LINE__ ." post: ");
		debug($status_code, __LINE__ ." status_code: ");
		debug($curl_errno, __LINE__ ." curl_errno: ");
		debug($curl_error, __LINE__ ." curl_error: ");
		debug($return, __LINE__ ." Results: ");
	}
	
	return $return;
}

	function GetCDR($config){
		/*
			Pass in the required and optional paramters, a cURL call is made to get the crd data.
			If successful the cdr data is returned with associated data in PHP Array format.
			If Debug is passed in as TRUE, an output of all variables is displayed
			
			Required Arguments in the config array: 
				pbxId
				startTime
				endTime
				timeZone
				pageSize
				8x8-apikey
				scrollId //when retrieving additional pages
				
			Optional Arguments in the config array: 
				debug
				isSimplified
				
			action: POST
			arguments: username password
				Example: "username=hugotestpbx.1012&password=Pass1234!" 
			header option: "8x8-apikey: <8x8_apikey>"
			
			URL:
				https://8x8gateway-prod.apigee.net/analytics/v1/oauth/token
				
			Returns:
			
				array in 3 parts
				
				array (size=2) -- Holds details on the success of the function calls 
					"success" => boolean true/false
					"results" =>
						array (size=2) -- Holds the top line results of the API call
							"meta" =>
								array (size=2) 
									"totalRecordCount" => int 171
									"scrollId" => string "c3VwZXJ0ZW5hbnRjc21fMTU0NzUzMjU1MjI0N18yXzE1NTExOTg5MjQ3MTk" (length=59)
							"data" =>
								array (size=100) -- Holds the actual CDR results
									0 =>
										array (size=48)
										...
									1 =>
										array (size=48)
										...
										
			See https://8x8gateway-voanalytics.apigee.io/api for full details on the API results
		*/
		
		$return = array();
		$return["success"] = true;
		
		//check for required
		if (!array_key_exists("pbxId",$config["voa"])){
			$return["success"] = false;
			$return["error"][] = "pbxId is missing";
		}
		
		if (!array_key_exists("startTime",$config["voa"])){
			$return["success"] = false;
			$return["error"][] = "startTime is missing";
		}
		
		if (!array_key_exists("endTime",$config["voa"])){
			$return["success"] = false;
			$return["error"][] = "endTime is missing";
		}
		
		if (!array_key_exists("timeZone",$config["voa"])){
			$return["success"] = false;
			$return["error"][] = "timeZone is missing";
		}
		
		if (!array_key_exists("pageSize",$config["voa"])){
			$return["success"] = false;
			$return["error"][] = "pageSize is missing";
		}
		
		if($return["success"] == true){ 
			$getArray = array();
			
			//Required Parameters
			$getArray[] = "pbxId=".strtolower($config["voa"]["pbxId"]);
			$getArray[] = "startTime=".$config["voa"]["startTime"];
			$getArray[] = "endTime=".$config["voa"]["endTime"];
			$getArray[] = "pageSize=".$config["voa"]["pageSize"];

			//Optional Parameters
			if (array_key_exists("isSimplified",$config["voa"])){
				$getArray[] = "isSimplified=".$config["voa"]["isSimplified"];
			}
			
			if (array_key_exists("scrollId",$config["voa"])){
				$getArray[] = "scrollId=".$config["voa"]["scrollId"];
			}
			
			if (array_key_exists("timeZone",$config["voa"])){
				$getArray[] = "timeZone=".$config["voa"]["timeZone"];
			}
			
			//array to string
			$getString = implode("&", $getArray);
			
			//set up cURL
			$url = "https://8x8gateway-prod.apigee.net/analytics/".$config["voa"]["version"]."/cdr?".$getString;
			$header = [
				"Authorization: Bearer ".$config["voa"]["access_token"], 
				"8x8-apikey: ".$config["voa"]["8x8-apikey"]
			];
			$ch = curl_init();
			curl_setopt($ch, CURLOPT_URL, $url);
			curl_setopt($ch, CURLOPT_CONNECTTIMEOUT ,30);
			curl_setopt($ch, CURLOPT_TIMEOUT, 400); //timeout in seconds
			curl_setopt($ch, CURLOPT_VERBOSE, false);
			curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
			curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
			curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_ANY);
			//custom header data
			curl_setopt($ch, CURLOPT_HTTPHEADER, $header);
			//execute curl
			$data = curl_exec($ch);
			$status_code = curl_getinfo($ch, CURLINFO_HTTP_CODE); //get status code
			$curl_errno = curl_errno($ch);
			$curl_error = curl_error($ch);
			
			curl_close($ch);
			
			//convert to Array
			$cdrArray = json_decode($data, true);
			if($status_code < 300){ 
			  $return["results"] = $cdrArray;
			} elseif ($status_code >= 500) {
			  echo "There was an issue. HTTP Status: " . $status_code . "." . PHP_EOL;
			  $return["success"] = false;
			  $return["error"]["message"] = "Server-side error message";
			  $return["error"]["code"] = "server_error";
			  $return["error"]["http_status"] = $status_code;
			} else {
			  echo "There was an issue. HTTP Status: " . $status_code . "." . PHP_EOL;
			  $return["success"] = false;
			  $return["error"]["message"] = $cdrArray["error_description"];
			  $return["error"]["code"] = $cdrArray["error"];
			  $return["error"]["http_status"] = $status_code;
			  if (array_key_exists("debug",$config["voa"]) && $config["voa"]["debug"] == true){
			    $return["results"] = $cdrArray;
			  }
		    }
	    }
          
          //show debug if requested
        if (array_key_exists("debug",$config["voa"]) && $config["voa"]["debug"] == true){
            debug($config["voa"], __LINE__ ." Config|VOA: ");
            debug($url, __LINE__ ." URL: ");
            debug($header, __LINE__ ." header: ");
            debug($status_code, __LINE__ ." status_code: ");
            debug($curl_errno, __LINE__ ." curl_errno: ");
            debug($curl_error, __LINE__ ." curl_error: ");
            debug($return, __LINE__ ." Results: ");
          }
          
        return $return;
    }
        
    function getlra($id){
        
          /*
            convert id to The last redirect address type 
          */
        
          $lraArray = array();
          $lraArray[0] = "None";
          $lraArray[1] = "VO Extension";
          $lraArray[2] = "External Telephone";
          $lraArray[3] = "Ring Group";
          $lraArray[4] = "Call Queue";
          $lraArray[5] = "Virtual Extension";
          $lraArray[6] = "Media Service";
          $lraArray[7] = "Park Extension";
        
          return $lraArray[$id];
        }
    function processCSV($data, $fileName) {
      $writeRow = fopen($fileName, "a");
      foreach ($data as $row) {
        $string='"';
        foreach( $row as $value) {
          if (is_array($value)) {
            $subString="";
            foreach($value as $subValue){
              $subString .= $subValue . "|";
            }
            $string .= substr($subString, 0, -1) . '","';
          } else {
            $value = preg_replace('/\\\\\"/', '', $value);
            $value = preg_replace('/,/', '|', $value);
            $string .= $value . '","';
          }
        }
          fwrite($writeRow, substr($string, 0, -2) . PHP_EOL);
      }
      fclose($writeRow);
    }
    
    function processSQL($data) {
      print_r($data);
    }
    
    //Set Configuration variables
        
    $config["voa"]["debug"] = false;    
    $config["voa"]["8x8-apikey"] = '';
    $config["voa"]["username"] = '';
    $config["voa"]["password"] = '';
    $config["voa"]["pbxId"] = 'allpbxes';

    $config["voa"]["version"] = "v1";
    $config["voa"]["isSimplified"] = "false";
//    $config["voa"]["timeZone"] = "America/New_York";
    $config["voa"]["timeZone"] = "UTC";
    date_default_timezone_set($config["voa"]["timeZone"]);
    $config["voa"]["startTime"] = date("Y-m-d%2000:00:00", strtotime('yesterday'));
    $config["voa"]["endTime"] = date("Y-m-d%2023:59:59", strtotime('yesterday'));
    $config["voa"]["pageSize"] = "7000";
    $output = "csv";
        
    //Get Required Token
    $token = GetToken($config);
    if($token["success"] == true){ //got token
      //add token to $config
      $config["voa"]["access_token"] = $token["results"]["access_token"];

      //get CDR Data
      echo "Process CDR Data" . PHP_EOL;
      
      while ($config["voa"]["scrollId"] . "" != 'No Data') {
        $cdr = GetCDR($config);
        if($cdr["success"] == true){ // got cdr 
          $server_error = 0;
          if ($config["voa"]["scrollId"] . "" == "") {
            echo "Total records: " . $cdr['results']['meta']['totalRecordCount'] . PHP_EOL;
            $remainingRecords = $cdr['results']['meta']['totalRecordCount'];
            switch ($output) {
              case "csv":
                $outputFileName = date('Y-m-d', strtotime($config["voa"]["startTime"])) . " - " . date('Y-m-d', strtotime($config["voa"]["endTime"])) . ".csv";
	            $outputFile = fopen($outputFileName, "w") or die("Unable to open file!");
	            fwrite($outputFile, implode(',', array_keys($cdr['results']['data'][0])) . PHP_EOL);
	            fclose($outputFile);
	            break;
	          case "sql":
	            $outputFile = date('Y-m-d', strtotime($config["voa"]["startTime"])) . " - " . date('Y-m-d', strtotime($config["voa"]["endTime"])) . ".sql";
	            break;
	          default:
	            $output = "csv";
	            $outputFile = date('Y-m-d', strtotime($config["voa"]["startTime"])) . " - " . date('Y-m-d', strtotime($config["voa"]["endTime"])) . ".csv";
	            echo implode(",", array_keys($cdr['results']['data'][0])) . PHP_EOL;
	            break;
	        }
          }
          $remainingRecords = $remainingRecords - count($cdr['results']['data']);
          $config["voa"]["scrollId"] = $cdr['results']['meta']['scrollId'];
          $scrollId=$cdr['results']['meta']['scrollId'];
          if ($cdr['results']['meta']['scrollId'] != 'No Data'){
            echo "Records remaining: " . $remainingRecords . PHP_EOL;
            switch ($output) {
              case "csv":
                processCSV($cdr['results']['data'], $outputFileName);
                break;
              case "sql":
                processSQL($cdr['results']['data']);
                break;
            }
          }
        } else {
          echo "The Server Error Code: " . $cdr['error']['code'] . PHP_EOL;
          switch ($cdr['error']['code']) {
            case "invalid_token": {
              echo "Renewing token" . PHP_EOL;
              $token = GetToken($config);
              $config["voa"]["access_token"] = $token["results"]["access_token"];
              break;
            }
            case "server_error": {
              switch ($server_error) {
                case 0: {
                  $server_error = 1;
                  echo "server_error = " . $server_error . PHP_EOL;
                  break;
                }
                case 1: {
                  $server_error = 2;
                  echo "server_error = " . $server_error . PHP_EOL;
                  break;
                }
                case 2: {
                  echo "We encountered a server side error and failed on 3 attempts. Please try again later." . PHP_EOL;
                  echo "HTTP Status: " . $cdr['http_status'] . PHP_EOL;
                  echo "server_error = " . $server_error . PHP_EOL;
                  $config["voa"]["scrollId"]='No Data';
                  break;
                }
              }
              break;
            }
            default: {
              echo "There was an error getting CDR" . PHP_EOL;
              $config["voa"]["scrollId"]='No Data';
              print_r($cdr);
            }  
          }
        }
      }
    } else {
      echo "There was an error getting Token" . PHP_EOL;
      print_r($token);
    }
?>