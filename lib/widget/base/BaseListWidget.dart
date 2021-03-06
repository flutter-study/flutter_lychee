import "dart:io";
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:lychee/common/style/Style.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:lychee/widget/base/BaseDecorationState.dart';
import 'package:lychee/widget/SeparatorWidget.dart';
import 'package:lychee/widget/base/BaseWidget.dart';

class BaseListWidget extends StatefulWidget {
  ///item渲染
  final IndexedWidgetBuilder itemBuilder;
  ///加载更多回调
  final RefreshCallback onLoadMore;
  ///下拉刷新回调
  final RefreshCallback onRefresh;
  ///控制器，比如数据和一些配置
  final BaseListWidgetControl control;
  final String emptyTip;
  final Key refreshKey;

  BaseListWidget({this.control, this.itemBuilder, this.onRefresh, this.onLoadMore, this.emptyTip, this.refreshKey});

  @override
  _BaseListWidgetState createState() => _BaseListWidgetState();
}

class _BaseListWidgetState extends State<BaseListWidget> with BaseDecorationState<BaseListWidget> {

  _BaseListWidgetState();

  final GlobalKey<RefreshHeaderState> _refreshHeaderKey = new GlobalKey<RefreshHeaderState>();
  final GlobalKey<RefreshFooterState> _refreshFooterKey = new GlobalKey<RefreshFooterState>();
  SlidableController slidableController = new SlidableController();

  _getListCount() {
    if (widget.control.needHeader) {
      return widget.control.data.length + 1;
    } else {
      if (widget.control.data.length == 0) {
        return 1;
      }

      return widget.control.data.length;
    }
  }

  @override
  Widget buildDecoration(control, onRefresh, emptyTip) {
    if (!control.needNetworkRequest) return null;

    if (control.isLoading&&control.data==null) {

      return buildActivityIndicator();
    
    } else if (!control.isLoading && control.errorMessage!=null && control.errorMessage.length!=0) {
    
      ///网络请求出错显示提示框
      return buildErrorTip(control.errorMessage,onRefresh);
    
    } else if (!control.needHeader && (control.data==null || (control.data!=null&&control.data.length == 0))) {
    
      ///如果不需要头部，并且数据为0，渲染空页面
      return buildEmpty(emptyTip);
    
    } 

    return null;
  }

  Widget buildListView() {

    return new ListView.builder(
      shrinkWrap: true,
      physics: new NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        if (widget.control.needSlide && widget.control.canNotSlideRows.contains(index) == false) {
          return Slidable(
            controller: slidableController,
            delegate: SlidableScrollDelegate(),
            actionExtentRatio: 0.18,
            secondaryActions: widget.control.slideActions(index),
            child: Column(
               children: <Widget>[
                 widget.itemBuilder(context, index),
                 SeparatorWidget()
               ],
            )
          );
        } else {
          return Column(
            children: <Widget>[
              widget.itemBuilder(context, index),
              SeparatorWidget()
            ],
          );
        }
      },
      itemCount: (widget.control.data==null)?0:_getListCount(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget decoration = buildDecoration(widget.control,widget.onRefresh,widget.emptyTip);
    if (decoration != null) return decoration; 

    return new EasyRefresh(
      key: widget.refreshKey,
      behavior: (Platform.isIOS)?ScrollOverBehavior():null,
      refreshHeader: ClassicsHeader(
        key: _refreshHeaderKey,
        refreshText: "下拉刷新",
        refreshReadyText: "释放刷新",
        refreshingText: "正在刷新...",
        refreshedText: "刷新结束",
        moreInfo: "更新于 %T",
        showMore: true,
        bgColor: Colors.white,
        textColor: Color(YYColors.primaryText),
        moreInfoColor: Color(YYColors.secondaryText),
      ),
      refreshFooter: ClassicsFooter(
        key: _refreshFooterKey,
        loadText: "上拉加载",
        loadReadyText: "释放加载",
        loadingText: "正在加载",
        loadedText: "加载结束",
        noMoreText: "没有更多数据",
        moreInfo: "更新于 %T",
        bgColor: Colors.white,
        textColor: Color(YYColors.primaryText),
        moreInfoColor: Color(YYColors.secondaryText),
        showMore: true,
      ),
      onRefresh:(widget.control.needRefreshHeader)?widget.onRefresh:null,
      loadMore:(widget.control.needRefreshFooter)?widget.onLoadMore:null,
      child: buildListView(),
    );
  }
}

typedef SlideActionsFunction = List<Widget> Function(int index);

class BaseListWidgetControl extends BaseWidgetControl {
  bool needRefreshHeader = true;
  bool needRefreshFooter = true;
  bool needHeader = false;
  bool needSlide = false;
  
  SlideActionsFunction slideActions;
  List<int> canNotSlideRows; 
}
