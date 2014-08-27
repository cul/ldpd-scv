window.SCV = window.SCV || function(){};
SCV.Filesystem = function(){};
SCV.Filesystem.folderHandler = function(){
  $(this).parent().children('UL').slideToggle({ done: function(){
    if ($(this).is(':visible')) $(this).parent().addClass('fs-expanded');
    else $(this).parent().removeClass('fs-expanded');
  }});
  return false;
}
SCV.Filesystem.fileHandler = function(){
  //TODO: modal for files
  return false;
}
SCV.Filesystem.bindHandlers = function() {
  window.console.log("bindHandlers")
  $('LI.fs-directory A').bind('click', SCV.Filesystem.folderHandler);
  $('LI.fs-file A').bind('click', SCV.Filesystem.fileHandler);
}
$(window).load(SCV.Filesystem.bindHandlers);