function askForDeletion(lang)
{
  var answer;

	if (lang == 'de') {
  	answer = confirm("Element wirklich l�schen?");
 	} else if (lang == 'fr') {
  	answer = confirm("Supprimer l'�l�ment?");
 	} else if (lang == 'en') {
  	answer = confirm("Delete item?");
	}
	
	if (answer) {
		return true;
	} else {
		return false;
	}
}

var screenHeight = window.innerHeight - 20;
document.cookie = "ScreenHeight=" + screenHeight;
