import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fort/fort.dart';
import 'package:piky/Pickers/giphy_picker.dart';
import 'package:piky/Pickers/imager_picker.dart';
import 'package:piky/state/state.dart';
class GiphyPickerPickerBuilderDelegate {
  GiphyPickerPickerBuilderDelegate(
    this.provider,
    this.gridScrollController,
    this.giphyPickerController,
    this.sheetExtent,
    this.sheetState,
    this.loadingIndicator,
    this.connectivityIndicator,
    this.loadingTileIndicator, {
      this.overlayBuilder,
      this.mediumExtent = 0.4,
    }
  );

  /// Overlay Widget of the selected asset
  final Widget Function(BuildContext context, int index)? overlayBuilder;

  /// Loading Indicator before any Gifs are loaded
  final Widget? Function(BuildContext, ScrollController, double)? loadingIndicator;

  /// When the giphy picker is not connected to the internet
  final Widget? Function(BuildContext, double)? connectivityIndicator;

  /// Individual Gif loading indicator
  final Widget? loadingTileIndicator;

  /// [ChangeNotifier] for giphy picker
  final Store<GiphyState> provider;

  /// The [ScrollController] for the preview grid.
  final ScrollController gridScrollController;

  /// Controls the changes in state relative to the [SlidingSheet]
  /// 
  /// If the state is changed the imagePicker can change certain
  /// params inside of the [GiphyPickerPickerBuilderDelegate] accordingly
  final GiphyPickerController? giphyPickerController;

  /// The primary [Cubit] for the headerBuilder inside [SlidingSheet]
  final ConcreteCubit<double> sheetExtent;

  /// The primary [Cubit] for the headerBuilder inside [SlidingSheet]
  final ConcreteCubit<bool> sheetState;

  /// Intial Extent
  final double mediumExtent;

  /// Primary [TextEditingController] to get the current value of the [TextField]
  TextEditingController searchFieldController = TextEditingController();

  ScrollController loading = ScrollController();

  /// Loading indicator
  Widget loadingIndicatorExample(BuildContext context){
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

  /// Overlays [imageItemBuilder] amd [videoItemBuilder] to display the slected state
  Widget selectedOverlay(BuildContext context){

    //Width of the screen
    var width = MediaQuery.of(context).size.width;
    
    return Stack(
      children: [
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
              child: Text('1', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
            )
          )
        )
      ],
    );
  }

  Widget loadingTileIndicatorExample(){
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey,
      ),
    );
  }

  Widget connectivityIndicatorExample(){
    return Container(
      child: Center(
        child: Text("Not Connected to the internel"),
      ),
    );
  }

  //Build all containers that hold the gifs
  Widget assetItemBuilder(String url, Map<String, double> currentAssets, int index){

    // Render individual asset
    Widget _displayImage(BuildContext context, String? selectedAsset){
      return Stack(
        children: [
          Positioned.fill(
            child: loadingTileIndicator ?? loadingTileIndicatorExample()
          ),
          Positioned.fill(
            child: Image.network(url,
              fit: BoxFit.cover,
            ),
          ),
          if (selectedAsset == currentAssets.keys.elementAt(index)) overlayBuilder != null ? overlayBuilder!(context, 1) : selectedOverlay(context)
        ],
      );
    }

    return StoreConnector<GiphyState, String?>(
      converter: (store) => store.state.selectedAsset,
      builder: (context, selectedAsset) {
        return FlatButton(
          padding: EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 300,
              minHeight: 125, 
            ),
            child: AnimationConfiguration.staggeredGrid(
              columnCount: (index / 2).floor(),
              position: index,
              duration: const Duration(milliseconds: 375),
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: _displayImage(context, selectedAsset)
                ),
              ),
            ),
          ),
          onPressed: (){
            if(selectedAsset == currentAssets.keys.elementAt(index))
              provider.dispatch(unSelectAsset());
            else provider.dispatch(selectAsset(currentAssets.keys.elementAt(index)));
            giphyPickerController!.update();
          },
        );
      }
    );
  }

  /// The primary grid view builder for assets
  Widget assetsGridBuilder(BuildContext context, double extent){

    //Height of the screen
    var height = MediaQuery.of(context).size.height;

    //Width of the screen
    var width = MediaQuery.of(context).size.width;


    return StoreConnector<GiphyState, Map<String, double>>(
      converter: (store) => store.state.displayAssets,
      builder: (context, displayAssets) {
        List<double> urlRatio = displayAssets.values.toList();
        return Container(
          height: extent > 0.55 ? (extent == 1.0 ? 
          extent*height - MediaQuery.of(context).padding.top - 60 : extent > 0.8 ? 
          extent*height - MediaQuery.of(context).padding.top : extent*height - 60) : 
          height*0.55 - 60,
          alignment: Alignment.topCenter,
          child: StaggeredGridView.countBuilder(
            controller: gridScrollController,
            shrinkWrap: false,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            padding: EdgeInsets.zero,
            itemCount: displayAssets.length,
            scrollDirection: Axis.vertical,
            crossAxisCount: 2,
            itemBuilder: (context, i){
              return assetItemBuilder(displayAssets.keys.elementAt(i), displayAssets, i);
            },
            staggeredTileBuilder: (int index) => StaggeredTile.extent(1, (width*0.5)/urlRatio[index] - 15),
          ),
        );
      }
    );
  }

  /// Yes, the build method
  Widget build(BuildContext context) {
    return StoreConnector<GiphyState, GiphyState>(
      converter: (store) => store.state,
      builder: (context, state){
        return BlocBuilder(
          bloc: sheetExtent,
          builder: (BuildContext context, double extent){
            if(state.displayAssets.length == 0 && !state.connectivity){
              return connectivityIndicator == null ? connectivityIndicatorExample() : connectivityIndicator!(context, extent)!;
            }
            else if(state.displayAssets.length > 0){
              return assetsGridBuilder(context, extent);
            }
            else{
              return loadingIndicator == null ? loadingIndicatorExample(context) : loadingIndicator!(context, gridScrollController, extent)!;
            }
          }
        );
      }
    );
  }
}