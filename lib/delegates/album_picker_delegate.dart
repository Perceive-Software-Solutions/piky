import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keyboard_media_picker/Pickers/imager_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';



class AlbumPickerBuilderDelegate {
  AlbumPickerBuilderDelegate(
    this.provider,
    this.pageCubit,
    this.imagePickerController, {
      this.gridCount = 3,
      this.overlayStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      this.albumNameStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      this.albumCountStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      this.backgroundColor = Colors.white
  });

  final TextStyle albumCountStyle;

  final TextStyle albumNameStyle;

  final TextStyle overlayStyle;

  final Color backgroundColor;

  /// [ChangeNotifier] for asset picker
  final DefaultAssetPickerProvider provider;

  /// Primary cubit for initiating page transitions
  final ConcreteCubit<bool> pageCubit;

  /// The column count inside of the [_sliverGrid]
  final int gridCount;

  /// Controls the changes in state relative to the [SlidingSheet]
  /// 
  /// If the state is changed the imagePicker can change certain
  /// params inside of the [ImagePickerBuilderDelegate] accordingly
  final ImagePickerController? imagePickerController;

  /// The [ScrollController] for the preview grid.
  final ScrollController gridScrollController = ScrollController();

  /// The [ScrollController] for the [SingleChildScrollView]
  final ScrollController mainScrollController = ScrollController();

  /// Keep a dispose method to sync with [State].
  ///
  /// Be aware that the method will do nothing when [keepScrollOffset] is true.
  void dispose() {
    gridScrollController.dispose();
    mainScrollController.dispose();
  }

  /// Whether the current platform is Apple OS.
  bool get isAppleOS => Platform.isIOS || Platform.isMacOS;

  //Takes an input [Key], and returns the index of the child element with that associated key, or null if not found.
  int findChildIndexBuilder(String id, List<AssetEntity> assets, {int placeholderCount = 0}) {
    int index = assets.indexWhere((AssetEntity e) => e.id == id);
    index += placeholderCount;
    return index;
  }

  /// Loading indicator
  Widget loadingIndicator(BuildContext context){
    return Center(
      child: SizedBox.fromSize(
        size: Size.square(48.0),
        child: CircularProgressIndicator(
            strokeWidth: 4.0,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            value: 1.0,
          ),
      ),
    );
  }

  /// Item widgets when the thumb data load failed.
  Widget failedItemBuilder(BuildContext context) {
    return Center(
      child: Container()
    );
  }

  /// Overlays [imageItemBuilder] amd [videoItemBuilder] to display the slected state
  List<Widget> selectedOverlay(BuildContext context, AssetEntity asset){

    //Width of the screen
    var width = MediaQuery.of(context).size.width;
    
    return [
      Positioned.fill(
        child: Opacity(
          opacity: 0.4,
          child: Container(
            height: width / 3,
            width: width / 3,
            color: Colors.black,
          ),
        ),
      ),
      Align(
        alignment: Alignment.center,
        child: Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:BorderRadius.circular(30)),
          child: Center(
            child: Text(
              (provider.selectedAssets.indexOf(asset) + 1).toString(),
              style: overlayStyle,
        )),
      ))
    ];
  }

  Widget thumbnailItemBuilder(
    BuildContext context, int index, Map<AssetPathEntity, Uint8List?> pathEntityList, int length, int placeHolder){

    Widget assetItemBuilder(){

      Uint8List? _thumbnail = pathEntityList[pathEntityList.keys.elementAt(index)];

      return AnimationConfiguration.staggeredGrid(
        columnCount: 2,
        position: index,
        child: ScaleAnimation(
          child: FadeInAnimation(
            child: GestureDetector(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Container(
                      width: 105,
                      height: 139,
                      child: _thumbnail != null ? Image.memory(
                        _thumbnail,
                        filterQuality: FilterQuality.high,
                        fit: BoxFit.fitWidth,
                      ) : Container()
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(pathEntityList.keys.elementAt(index).name, style: albumNameStyle),
                  ),
                  Text(pathEntityList.keys.elementAt(index).assetCount.toString(), style: albumCountStyle)
                ],
              ),
              onTap: () {
                provider.currentPathEntity = pathEntityList.keys.elementAt(index);
                provider.getAssetsFromEntity(0, pathEntityList.keys.elementAt(index));
                if(pageCubit.state) pageCubit.emit(false);
              },
            ),
          ),
        ),
      );
    }

    if(pathEntityList[index]?.isNotEmpty ?? true)
      return assetItemBuilder();
    else
      return SizedBox.shrink();
    
  }

  /// The main grid view builder for assets
  Widget assetsGridBuilder(BuildContext context){

    //Width of the screen
    var width = MediaQuery.of(context).size.width;

    return Selector<DefaultAssetPickerProvider, Map<AssetPathEntity, Uint8List?>>(
      selector: (_, DefaultAssetPickerProvider p) => p.pathEntityList,
      builder: (_, Map<AssetPathEntity, Uint8List?> pathEntityList, __) {

         // First, we need the count of the assets.
        int totalCount = pathEntityList.length;

        // Then we use the [totalCount] to calculate how many placeholders we need.
        int placeholderCount = 0;

        if (totalCount % gridCount != 0) {
          // When there are left items that not filled into one row, filled the row
          // with placeholders.
          placeholderCount = gridCount - totalCount % gridCount;
        } else {
          // Otherwise, we don't need placeholders.
          placeholderCount = 0;
        }

        Widget _materialGrid(BuildContext c, Map<AssetPathEntity, Uint8List?> assets){
          return GridView.extent(
            childAspectRatio: 0.5,
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
            maxCrossAxisExtent: width / 3,
            children: [
              for(int i = 0; i < pathEntityList.length + placeholderCount + gridCount; i++)
                if(i >= pathEntityList.length)
                  SizedBox.shrink()
                else
                  thumbnailItemBuilder(context, i, assets, pathEntityList.length, placeholderCount)
            ],
          );
        }

        return BlocBuilder<ConcreteCubit<bool>, bool>(
          builder: (context, state) {
            return _materialGrid(_, pathEntityList);
          }
        );
      }
    );
  } 
  
  /// Yes, the build method
  Widget build(BuildContext context){

    //Width of the screen
    var width = MediaQuery.of(context).size.width;

    //height of the screen
    var height = MediaQuery.of(context).size.height;
    
    return ChangeNotifierProvider<DefaultAssetPickerProvider>.value(
      value: provider,
      builder: (BuildContext context, _) {
        return Container(
          color: backgroundColor,
          height: height,
          width: width,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 5),
            child: assetsGridBuilder(context),
          ),
        );
      }, 
    );
  }
}