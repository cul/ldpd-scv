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
  SCV.Filesystem.modalPreview($(this).attr('data-id'));
  return false;
}
SCV.Filesystem.bindHandlers = function() {
  window.console.log("bindHandlers")
  $('LI.fs-directory A').bind('click', SCV.Filesystem.folderHandler);
  $('LI.fs-file A').bind('click', SCV.Filesystem.fileHandler);
}
SCV.Filesystem.modalPreview = function(dataId){

  $.colorbox({
    href: '/previews/' + encodeURIComponent(dataId),
    className: 'cul-no-colorbox-title-bar',
    height:"500px",
    width:"700px",
    maxHeight:"90%",
    maxWidth:"90%",
    opacity:".6",
    fixed:true,
    iframe:true,
    preloading: false,
    current: false,
    title: false
  });

  return false;
};
$(window).load(SCV.Filesystem.bindHandlers);