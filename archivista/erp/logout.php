<?php

$page_security = 1;
$path_to_root=".";
include($path_to_root . "/includes/session.inc");
include_once($path_to_root . "/includes/ui/ui_view.inc");

page(tr("Logout"), true, false, "", get_js_png_fix());

?>

<table width="100%" border="0">
  <tr>
	<td align="center"><img src="<?php echo "$path_to_root/themes/default/images/logo_archivistaerp.png";?>" alt="ArchivistaERP" onload="fixPNG(this)"></td>
  </tr>
  <tr>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td><div align="center"><font size=2>
<?php
    		echo tr("Thank you for using") . " ";

			echo "<strong>$app_title $version</strong>";
?>
         </font></div></td>
  </tr>
  <tr>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td><div align="center">
        <?php
     echo "<a href='$path_to_root/index.php?" . SID ."'><b>" . tr("Click here to Login Again.") . "</b></a>";
?>
      </div></td>
  </tr>
</table>
<br>
<?php

	end_page();
	session_unset();
	session_destroy();

?>


