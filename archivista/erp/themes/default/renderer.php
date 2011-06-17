<?php
class renderer {
  function showmenu($appfunction) {
	  if ($_SESSION["wa_current_user"]->can_access_page($appfunction->access)) {
		  echo "<a href='$appfunction->link'> ".$appfunction->label."</a><br>";
		}
  }
	function wa_header() { page(tr("Main Menu"), false, true); }
	function wa_footer() { end_page(false, true); }
	function menu_header(&$menu) {}
	function menu_footer(&$menu) {}
	function display_applications(&$waapp) {
		$selected_app = $waapp->get_selected_application();
		foreach ($selected_app->modules as $module) {
			echo "<tr>";
			echo "<td valign='top' class='menu_group'>";
			echo "<table border=0 width='100%'>";
			echo "<tr><td class='menu_group'>";
			echo $module->name;
			echo "</td></tr><tr>";
			echo "<td class='menu_group_items'>";
			foreach ($module->lappfunctions as $appfunction) {
			  $this->showmenu($appfunction);
			}
			echo "</td>";
			if (sizeof($module->rappfunctions) > 0) {
				echo "<td width='50%' class='menu_group_items'>";
				foreach ($module->rappfunctions as $appfunction) {
				  $this->showmenu($appfunction);
				}
	      echo "</td>";
			}
			echo "</tr></table></td></tr>";
		}
		echo "</table>";
	}
}
?>
