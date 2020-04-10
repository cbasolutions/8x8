<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<link href="https://fonts.googleapis.com/css?family=Roboto:400,700" rel="stylesheet">
<title>8x8 API Account Creation</title>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script> 
<style type="text/css">
	body{
		color: #fff;
		background: #63738a;
		font-family: 'Roboto', sans-serif;
	}
    .form-control{
		height: 40px;
		box-shadow: none;
		color: #969fa4;
	}
	.form-control:focus{
		border-color: #5cb85c;
	}
    .form-control, .btn{        
        border-radius: 3px;
    }
	.signup-form{
		width: 400px;
		margin: 0 auto;
		padding: 30px 0;
	}
	.signup-form h2{
		color: #636363;
        margin: 0 0 15px;
		position: relative;
		text-align: center;
    }
    .modal h4{
		color: #636363;
        margin: 0 0 12px;
		position: relative;
		text-align: center;
    }
	.signup-form h2:before, .signup-form h2:after{
		content: "";
		height: 2px;
		width: 20%;
		background: #d4d4d4;
		position: absolute;
		top: 50%;
		z-index: 2;
	}	
	.signup-form h2:before{
		left: 0;
	}
	.signup-form h2:after{
		right: 0;
	}
    .signup-form .hint-text{
		color: #999;
		margin-bottom: 30px;
		text-align: center;
	}
	.modal-body .hint-text{
		color: #000;
		margin: 30px;
	}
    .signup-form form{
		color: #999;
		border-radius: 3px;
    	margin-bottom: 15px;
        background: #f2f3f7;
        box-shadow: 0px 2px 2px rgba(0, 0, 0, 0.3);
        padding: 30px;
    }
	.signup-form .form-group{
		margin-bottom: 20px;
	}
	.signup-form input[type="checkbox"]{
		margin-top: 3px;
	}
	.signup-form .btn{        
        font-size: 16px;
        font-weight: bold;		
		min-width: 140px;
        outline: none !important;
    }
	.signup-form .row div:first-child{
		padding-right: 10px;
	}
	.signup-form .row div:last-child{
		padding-left: 10px;
	}    	
    .signup-form a{
		color: #fff;
		text-decoration: underline;
	}
    .signup-form a:hover{
		text-decoration: none;
	}
	.signup-form form a{
		color: #5cb85c;
		text-decoration: none;
	}	
	.signup-form form a:hover{
		text-decoration: underline;
	}  
	input[type="number"]::-webkit-outer-spin-button,
	input[type="number"]::-webkit-inner-spin-button {
        -webkit-appearance: none;
        margin: 0;
    }
    input[type="number"] {
		-moz-appearance: textfield;
	}
</style>
</head>
<body>
<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
$tenant="";
$token="";

$url="https://platform.8x8.com/udi/customers/" . $tenant . "/scim/v2/Users";
$post_data = array(
	'userName' => $_POST["email"],
	'name' => array(
		'familyName' => $_POST["last_name"],
		'givenName' => $_POST["first_name"],
	),
	'active' => true,
	'locale' => 'en-US',
	'emails' => array(
		array(
			'value' => $_POST["email"],
			'type' => 'work',
			'primary' => true,
		),
	),
	'externalId' => $_POST["eid"]
);
$options = array(
  'http' => array(
  	'ignore_errors' => TRUE,
    'method'  => 'POST',
    'content' => json_encode( $post_data ),
    'header'=>  "Content-Type: application/json\r\n" .
                "Accept: application/json\r\n" .
                "Authorization: Bearer " . $token
    )
);

$context  = stream_context_create( $options );
$result = file_get_contents( $url, false, $context );
$response = json_decode($result,true);
if (array_key_exists('id', $response)) {
echo '<div class="container">' . "\r\n";
echo '<div class="modal fade" id="myModal" role="dialog">' . "\r\n";
echo '  <div class="modal-dialog">' . "\r\n";
echo '    <div class="modal-content">' . "\r\n";
echo '      <!-- Modal Header -->' . "\r\n";
echo '      <div class="modal-header">' . "\r\n";
echo '        <h4 class="modal-title">Creation Successful</h4>' . "\r\n";
echo '        <button type="button" class="close" data-dismiss="modal">&times;</button>' . "\r\n";
echo '      </div>' . "\r\n";
echo '      <div class="modal-body">' . "\r\n";
echo '        <p class="hint-text">User ' . $response["name"]["givenName"] . ' ' . $response["name"]["familyName"] . ' was created using email ' . $response["emails"]["value"] . ' and employee ID ' . $response["externalId"] . '.</br>The username is ' . $response["userName"] . '</p>' . "\r\n";
echo '      </div>' . "\r\n";
echo '      <!-- Modal footer -->' . "\r\n";
echo '      <div class="modal-footer">' . "\r\n";
echo '          <a class="btn-primary pull-left btn btn-success" href="https://vo-cm.8x8.com/users/user/edit/' . $response['id'] . '" target="_blank">Edit User</a>' . "\r\n";
echo '          <button type="button" class="btn-default btn btn-danger" data-dismiss="modal">Close</button>' . "\r\n";
echo '      </div>' . "\r\n";
echo '    </div>' . "\r\n";
echo '  </div>' . "\r\n";
echo '</div>' . "\r\n";
echo '</div>' . "\r\n";
echo '<script>$("#myModal").modal("show");</script>' . "\r\n";
}
}
?>
<div class="signup-form">
    <form action="#" method="post">
		<h2>8x8 User Info</h2>
		<p class="hint-text">Fill out the form, submit and finish the configuration in <a href="https://vo-cm.8x8.com" target="_blank">CM</a>.</p>
        <div class="form-group">
			<div class="row">
				<div class="col-xs-6"><input type="text" class="form-control" name="first_name" placeholder="First Name" required="required"></div>
				<div class="col-xs-6"><input type="text" class="form-control" name="last_name" placeholder="Last Name" required="required"></div>
			</div>      
			<div class="row">
				<div class="col-xs-6"><input type="email" class="form-control" name="email" placeholder="Email" required="required"></div>
				<div class="col-xs-6"><input type="number" min="1" step="1" class="form-control" name="eid" placeholder="Employee ID" required="required"></div>
			</div>    	
        </div>
		<div class="form-group">
            <button type="submit" class="btn btn-success btn-lg btn-block">Create Account</button>
        </div>
    </form>
</div>
</body>
</html>
