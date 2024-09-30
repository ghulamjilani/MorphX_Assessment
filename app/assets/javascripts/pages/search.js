// $(document).ready(function () {
//   if ($('body').hasClass('search-show')) {
//     var $select_type_select = $(".searchB-basic-multiple");
//     var $select_type_select_selected = $(".searchB-basic-multiple option:selected");
//     var $select_type_tag = $("#TagsSELECT");
//     var $myList = $('#sessions .tagList');
//     var $myListItemClose = $('#sessions .tagList i');
//
// //  добавляем при инициализации странички, все что было по умолчание в option:selected
//     $select_type_select_selected.each(function (e) {
//       var $select_id = $(this).parent('select').attr('id');
//       var $select_val = $(this).val();
//       var $select_text = $(this).text();
//       $myList.prepend('<span data-select-type="select" data-select-Parent="' + $select_id + '" data-select-id="' + $select_val + '">' + $select_text + '<i onclick="removeSelectItem(this);" class="CloseChosenTagIcon"></i></span>');
//     });
//
//
// //    init select and add option on change
//     $.each($select_type_select, function () {
//
//       var self = this;
//       $(this).select2({
//         placeholder: $(self).data('placeholder')
//       }).change(function (e) {
//         if (e.added) {
// //          console.log('added: ' + e.added.text + ' id ' + e.added.id);
//           $myList.prepend('<span data-select-type="select" data-select-Parent=' +  $(e.currentTarget).attr('id') + ' data-select-id=' + e.added.id + '>' + e.added.text + '<i onclick="removeSelectItem(this);" class="CloseChosenTagIcon"></i></span>');
//         }
//         else if (e.removed) {
//           $myList.find("[data-select-id='" + e.removed.id + "']").remove();
// //          console.log('removed: ' + e.removed.text + ' id ' + e.removed.id);
//         }
// //        console.log(e);
// //        console.log($(this).val())
//       });
//     });
//
//
//     //add tags on load
//     if ($select_type_tag.length > 0) {
//         $select_type_tag_list = $select_type_tag.val().split(',');
//     } else {
//         $select_type_tag_list = [];
//     }
// //    console.log($select_type_tag_list);
//
//     var arr = $select_type_tag_list;
//     var textToInsert = [];
//     var i = 0;
//     var length = arr.length;
//     for (var a = 0; a <length; a += 1) {
//       if (arr[a] != '') {
//         textToInsert[i++] = '<span data-select-type="tag"  data-select-id='+ arr[a] +'>';
//         textToInsert[i++] = arr[a];
//         textToInsert[i++] = '<i onclick="removeSelectItem(this);" class="CloseChosenTagIcon"></i></span>' ;
//       }
//     }
//     $myList.append(textToInsert.join(''));
//
//
//     //init taglist and add tags on change
//     $(".searchB-basic-Tags").select2({
//       tags: true,
//       tokenSeparators: [',', ' '],
//       tags: Immerss.channelTags
//     }).on("change", function (e) {
//       if (e.added) {
// //        console.log('added: ' + e.added.text + ' id ' + e.added.id);
//         $myList.prepend('<span data-select-type="tag"  data-select-id=' + e.added.id + '>' + e.added.text + '<i onclick="removeSelectItem(this);" class="CloseChosenTagIcon"></i></span>');
//
//       } else if (e.removed) {
//         $myList.find("[data-select-id='" + e.removed.id + "']").remove();
// //        console.log($myList.find("[data-select-id='" + e.removed.id + "']"));
// //        console.log('removed: ' + e.removed.text + ' id ' + e.removed.id);
//       }
//     });
//   }
//
//     $( ".MaxHeight500" ).scroll(function() {
//         $('#formSubmit').hide();
//     });
//
//     $('.tab-content').delegate('.paginate a, .searchDropDown-content a, .filtersWrapp a', 'click', function(e){
//         $('.searchB-BR').prepend('<div class="LoadingCover"><div class="spinnerSlider"><div class="bounceS1"></div><div class="bounceS2"></div><div class="bounceS3"></div></div></div>');
//     });
//
//     var notlim = $('.thumbnails.thumbnail-kenburn.kontainer');
//     $.each(notlim, function() {
//         var imgOBJ, imgOBJItem, itemattr;
//         imgOBJ = $(this).find('.owl-lazy');
//         imgOBJItem = $(imgOBJ).get(0);
//         itemattr = $(imgOBJItem).attr('data-src');
//         $(imgOBJItem).css({
//             'background-image': 'url("' + itemattr + '")',
//             'opacity': 1
//         });
//     });
// });
//
// function removeSelectItem(elem){
//
//     var $selectParent = $(elem).parent('span').data("select-parent");
//     var $selectID = $(elem).parent('span').data("select-id");
//
//     if($(elem).parent('span').data("select-type") === 'tag'){
//       $('#s2id_TagsSELECT').find("[data-id='" + $selectID + "']").children('.select2-search-choice-close').click();
//     }
//     else if($(elem).parent('span').data("select-type") === 'select'){
//
//       var $selectParent = $(elem).parent('span').data("select-parent");
//       var $selectID = $(elem).parent('span').data("select-id");
//       $('#s2id_' + $selectParent).find("[data-id='" + $selectID + "']").children('.select2-search-choice-close').click();
//     }
// }
