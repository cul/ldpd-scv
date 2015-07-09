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
  SCV.Filesystem.popoverPreview($(this),$(this).attr('data-uri'));
  return false;
}
SCV.Filesystem.bindHandlers = function() {
  window.console.log("bindHandlers");
  //$('LI.fs-directory A').bind('click', SCV.Filesystem.folderHandler);
  var prevent = function(e) {e.preventDefault(); return true;};
  $('.fs-file A.preview').bind('click', prevent);
  $('.fs-file A.preview').each(SCV.Filesystem.popoverPreview);
}
SCV.Filesystem.modalPreview = function(dataId){

  $.colorbox({
    href: '/previews/' + encodeURIComponent(dataId),
    className: 'cul-no-colorbox-title-bar',
    height:"800px",
    width:"800px",
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
SCV.Filesystem.popoverPreview = function(index){
  var dataUri = $(this).attr('data-uri');
  var label = $(this).attr('data-label');
  var image = '<div class="thumbnail"><img src="' + dataUri + '"/></div><div class="caption">' + label + '</div>';
  window.console.log("popoverPreview " + image);
  $(this).popover({placement: 'bottom', content: image, html: true});
};
$(window).load(SCV.Filesystem.bindHandlers);