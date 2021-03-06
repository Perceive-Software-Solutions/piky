
import 'package:example/delegates/custom_delegate.dart';
import 'package:example/delegates/giphy_delegate.dart';
import 'package:example/delegates/image_delegate.dart';
import 'package:flutter/material.dart';
import 'package:piky/piky.dart';

import 'package:flutter_bloc/flutter_bloc.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(key: Key('MyHomePage'), title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({required Key key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late PickerController pickerController;

  List<AssetEntity> imageAssets = <AssetEntity>[];

  String? gifAsset;

  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();

    scrollController = ScrollController();
    pickerController = PickerController(
      onGiphyReceived: (value){
        setState(() {
          imageAssets.clear();
          gifAsset = value!;
        });
      },
      onImageReceived: (value){
        setState(() {
          gifAsset = null;
          imageAssets = value!;
        });
      } 
    );
  }

  /// Item widgets when the thumb data load failed.
  Widget failedItemBuilder(BuildContext context) {
    return Center(
      child: Container()
    );
  }

  /// Displays an individual asset
  Widget _displayImageAssets(AssetEntity imageAsset){

    int defaultGridThumbSize = 200;

    final AssetEntityImageProvider imageProvider = AssetEntityImageProvider(
      imageAsset,
      isOriginal: false,
      thumbSize: <int>[defaultGridThumbSize, defaultGridThumbSize],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 300,
        minHeight: 125, 
      ),
      child: AssetEntityGridItemBuilder(
        image: imageProvider,
        failedItemBuilder: failedItemBuilder,
      ),
    );
  }

  /// Displays the selected assets inside a wrap
  Widget _displayWrap(List<AssetEntity> imageAssets){
    return Wrap(
      children: [
        for(AssetEntity asset in imageAssets)
          _displayImageAssets(asset)
      ],
    );
  }

  /// Displays an individual gif using [NetworkImage]
  Widget _displayGifAsset(BuildContext context, String gif){

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 200,
        minHeight: 125,
        maxWidth: 200
      ),
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey,
        image: DecorationImage(
          image: NetworkImage(gif),
            fit: BoxFit.cover
          ),
        ),
      ),
    );
  }

  Widget gifConnectivityIndicator(BuildContext context, double extent){
    return Container(
      child: Text("This is the connectivity loading state"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Picker(
      initialValue: PickerType.Custom,
      controller: pickerController,
      backgroundColor: Colors.white,
      initialExtent: 0.2,
      minExtent: 0.2,
      mediumExtent: 0.55,
      expandedExtent: 1.0,
      maxBackdropColor: Colors.black.withOpacity(0.4),
      imagePickerDelegate: ExampleImagePickerConfigDelegate(scrollController: scrollController),
      giphyPickerDelegate: ExampleGiphyPickerConfigDelegate(apiKey: 'Example'),
      customPickerDelegate: ExampleCustomPickerConfigDelegate(),
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,
          floatingActionButton: GestureDetector(
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.blue
              ),
            ),
            onTap: (){
              pickerController.closePicker();
            },
          ),
          body: Column(
            children: [
              Spacer(),
              Container(
                child: Center(
                  child: Text('Picker', style: TextStyle(fontSize: 40),),
                ),
              ),
              Spacer(),
              GestureDetector(
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 1.5)),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Icon(
                      Icons.expand,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                onTap: () async {
                  if(pickerController.isOpen){
                    pickerController.closePicker();
                  }
                  else{
                    pickerController.openPicker();
                  }
                },
              ),
              Spacer(),
              Row(
                children: [
                    Spacer(),
                  GestureDetector(
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 1.5)),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(
                          Icons.add,
                          color: Colors.grey,
                          size: 34,
                        ),
                      ),
                    ),
                    onTap: () async {
                      if(pickerController.isOpen){
                        pickerController.openImagePicker(imageCount: 5, overrideLock: true);
                      }
                      else{
                        pickerController.openImagePicker(imageCount: 5, overrideLock: false);
                      }
                    },
                  ),
                  Spacer(),
                  GestureDetector(
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 1.5)),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(
                          Icons.add,
                          color: Colors.grey,
                          size: 34,
                        ),
                      ),
                    ),
                    onTap: () async {
                      if(pickerController.isOpen){
                        pickerController.openGiphyPicker(true);
                      }
                      else{
                        pickerController.openGiphyPicker(false);
                      }
                    },
                  ),
                  Spacer(),
                  GestureDetector(
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 1.5)),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(
                          Icons.add,
                          color: Colors.grey,
                          size: 34,
                        ),
                      ),
                    ),
                    onTap: () async {
                      if(pickerController.isOpen){
                        pickerController.openCustomPicker(true);
                      }
                      else{
                        pickerController.openCustomPicker(false);
                      }
                    },
                  ),
                  Spacer()
                ],
              ),
              Spacer(),
              imageAssets.isNotEmpty ? 
              _displayWrap(imageAssets) :
              gifAsset != "" && gifAsset != null ?
              _displayGifAsset(context, gifAsset!) :
              Container(),
              Spacer()
            ],
          )
        ),
    );

  }
}

class ConcreteCubit<T> extends Cubit<T> {
  ConcreteCubit(T initialState) : super(initialState);
}
