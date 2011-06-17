<?php
	if (!isset($path_to_root) || isset($_GET['path_to_root']) || isset($_POST['path_to_root']))
		die("Restricted access");
	include_once($path_to_root . "/includes/ui/ui_view.inc");
	// Display demo user name and password within login form if "$allow_demo_mode" is true
	$demo_text = "";
	if ($allow_demo_mode == True)
	{
	    $demo_text = "Login as user: demouser and password: cooldemo";
	}
	else
	{
		$demo_text = "Please login here";
	}
	if (!isset($def_coy))
		$def_coy = 0;
	$def_theme = $path_to_root . '/themes/default';
?>
<html>
<head>
<?php echo get_js_png_fix(); ?>
<script type="text/javascript">
function defaultCompany()
{
	document.forms[0].company_login_name.options[<?php echo $def_coy; ?>].selected = true;
}
</script>
    <title><?php echo $app_title . " " . $version;?></title>
    <meta http-equiv="Content-type" content="text/html; charset=iso-8859-1" />
    <link rel="stylesheet" href="<?php echo $def_theme;?>/login.css" type="text/css" />
</head>

<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" onload="defaultCompany()">

  <?php 
    if (!file_exists('/etc/erp.conf')) {
      echo "<br><h3>&nbsp;&nbsp;Please first enable ArchivistaERP!</h3>";
	    echo "</body></html>";
	    exit;
	  }
  ?>

  <?php
		if (!file_exists("/etc/nologinext.conf")) {
      echo '<table border=0><tr><td><p><font size="1">&nbsp;';
	    echo '<a href="/perl/avclient/index.pl">WebClient</a>';
	    echo ' - ';
	    echo '<a href="/erp">WebERP</a>';
	    echo ' - ';
	    echo '<a href="/cgi-bin/webadmin/index.pl">WebAdmin</a>';
	    echo ' - ';
	    echo '<a href="/perl/webconfig/index.pl">WebConfig</a>';
	    echo ' - ';
	    echo '<a href="/manual.pdf">Manual</a>';
	    echo ' - ';
	    echo '<a href="/handbuch.pdf">Handbuch</a>';
	    echo '</td></td></table></font></p>';
		}
	?>

  <form action="<?php echo $_SERVER['PHP_SELF'];?>" name="loginform" method="post">
  <table width="100%" height="95%" border="0" cellpadding="0" cellspacing="0" bgcolor="#fffafa">
    <tr>
       <td colspan="5">
			   <img src="<?php echo $def_theme; ?>/images/spacer.png" height="20" alt="" />
			 </td>
		</tr><tr>
		  <td>&nbsp;</td>
      <td align="center" valign="middle" width="250">
			  <a target="_blank" href="<?php $power_url; ?>">
				  <img src="<?php echo $def_theme;?>/images/logo_archivistaerp.png" 
					     alt="ArchivistaERP" onload="fixPNG(this)" border="0" />
				</a>
			</td>
      <td width="10">&nbsp;</td>
			<td class="loginText" width="300"><font size=4 color="#285b86">
			  <?php echo "<strong>$app_title $version</strong>"; ?><br></font><br>
			  <span><?php echo tr("User name:"); ?></span><br />
				  <input type="text" name="user_name_entry_field"/><br />
        <span><?php echo tr("Password:"); ?></span><br />
				  <input type="password" name="password"><br />
				<span><?php echo tr("Company:"); ?></span></br><select name="company_login_name">
<?php
for ($i = 0; $i < count($db_connections); $i++)
{
	echo "<option value=$i>" . $db_connections[$i]["name"] . "</option>";
}
?>
        </select><br /><br /><?php echo $demo_text;?>
				  <input type="submit" value="<?php echo tr("Login"); ?>" name="SubmitUser" />
      </td>
		  <td>&nbsp;</td>
    </tr><tr>
		  <td align="center" colspan="5" class="footer">
		    <font size=1><a target='_blank' style="text-decoration: none" HREF='
			    <?php echo $power_url ?>'><?php echo $power_by . " -- " .
					  tr("Version") . " " . $version. " -- Build " . $build_version ?>
				</a></font>
		  </td>
		</tr>
	</table>
  <?php
if ($allow_demo_mode == true)
{
    ?>
    <?php
}
?>
    <script language="JavaScript" type="text/javascript">
    //<![CDATA[
            <!--
            document.forms[0].user_name_entry_field.select();
            document.forms[0].user_name_entry_field.focus();
            //-->
    //]]>
  </script>
	</form>
</body>
</html>
