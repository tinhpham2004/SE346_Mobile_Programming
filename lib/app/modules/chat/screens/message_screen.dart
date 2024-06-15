import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dafa/app/core/values/app_colors.dart';
import 'package:dafa/app/core/values/app_text_style.dart';
import 'package:dafa/app/modules/chat/chat_controller.dart';
import 'package:dafa/app/modules/chat/widgets/add_message_field.dart';
import 'package:dafa/app/modules/chat/widgets/block_button.dart';
import 'package:dafa/app/modules/chat/widgets/pick_photo_button.dart';
import 'package:dafa/app/modules/chat/widgets/report.dart';
import 'package:dafa/app/modules/chat/widgets/send_message_button.dart';
import 'package:dafa/app/modules/chat/widgets/call_button.dart';
import 'package:dafa/app/modules/chat/widgets/take_photo_button.dart';
import 'package:dafa/app/modules/chat/widgets/unblock_button.dart';
import 'package:dafa/app/modules/chat/widgets/video_player_widget.dart';
import 'package:dafa/app/modules/sign_in/sign_in_controller.dart';
import 'package:dafa/app/routes/app_routes.dart';
import 'package:dafa/app/services/database_service.dart';
import 'package:dafa/app/services/firebase_listener_service.dart';
import 'package:dafa/app/services/firebase_messaging_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class MessageScreen extends StatefulWidget {
  MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final ChatController chatController = Get.find<ChatController>();

  final SignInController signInController = Get.find<SignInController>();

  final FirebaseListenerService firebaseListenerService =
      FirebaseListenerService();

  final firebaseMessagingService = FirebaseMessagingService();

  DatabaseService databaseService = DatabaseService();

  Stream<QuerySnapshot> messageStream = FirebaseFirestore.instance
      .collection('messages')
      .orderBy('time', descending: true)
      .snapshots();

  int minIndex = 100;

  void InitNotifyMessaging() {
    if (chatController.compatibleUserList.length <
        signInController.compatibleList.length) {
      for (int i = 0; i < signInController.matchListForChat.length; i++) {
        for (int j = 0; j < signInController.compatibleList.length; j++) {
          if (signInController.matchListForChat[i].user!.phoneNumber ==
                  signInController.compatibleList[j] &&
              chatController.compatibleUserList
                      .contains(signInController.matchListForChat[i]) ==
                  false) {
            chatController.compatibleUserList
                .add(signInController.matchListForChat[i]);
          }
        }
      }
    }
    if (signInController.notifySenderId != '') {
      for (int i = 0; i < chatController.compatibleUserList.length; i++) {
        if (chatController.compatibleUserList[i].user!.phoneNumber ==
            signInController.notifySenderId) {
          chatController.UpdateCurrIndex(i);
        }
      }
      signInController.notifySenderId = '';
    }
  }

  String TimeFormat(String time) {
    if (time.length < 2) time = '0' + time;
    return time;
  }

  @override
  void initState() {
    super.initState();
    chatController.UpdateLastestMessgage('');
    chatController.UpdateSuggestRep('');
    InitNotifyMessaging();
    firebaseListenerService.UpdateBlock(chatController
        .compatibleUserList[chatController.currIndex.value].user!.phoneNumber);
    firebaseListenerService.UpdateIsBlock(chatController
        .compatibleUserList[chatController.currIndex.value].user!.phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            titleSpacing: 2,
            leading: GestureDetector(
              onTap: () {
                Get.toNamed(AppRoutes.chat);
              },
              child: Icon(Icons.arrow_back_ios_new),
            ),
            title: ListTile(
              leading: GestureDetector(
                onTap: () {
                  Get.toNamed(AppRoutes.view_profile);
                },
                child: CircleAvatar(
                  backgroundImage: NetworkImage(chatController
                      .compatibleUserList[chatController.currIndex.value]
                      .user!
                      .images
                      .first),
                ),
              ),
              title: Text(
                chatController
                    .compatibleUserList[chatController.currIndex.value]
                    .user!
                    .name,
                style: CustomTextStyle.chatUserNameStyle(AppColors.black),
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
              subtitle: Obx(
                () => Text(
                  (signInController.listUsersOnlineState[chatController
                              .compatibleUserList[
                                  chatController.currIndex.value]
                              .user!
                              .phoneNumber] ==
                          true)
                      ? 'online'
                      : 'offline',
                  style: TextStyle(fontSize: 23.sp),
                ),
              ),
              trailing: Wrap(
                children: [
                  Obx(
                    () => chatController.isBlock.value == false &&
                            chatController.block.value == false
                        ? CallButton(isVideoCall: false)
                        : SizedBox(),
                  ),
                  Obx(
                    () => chatController.isBlock.value == false &&
                            chatController.block.value == false
                        ? SizedBox(width: 20.w)
                        : SizedBox(),
                  ),
                  Obx(
                    () => chatController.isBlock.value == false &&
                            chatController.block.value == false
                        ? CallButton(isVideoCall: true)
                        : SizedBox(),
                  ),
                  BlockButton(
                      databaseService: databaseService,
                      chatController: chatController),
                  Report(chatController: chatController),
                ],
              ),
            ),
          ),
          body: Stack(
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 200.h),
                child: StreamBuilder(
                  stream: messageStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Something went wrong',
                        style: CustomTextStyle.error_text_style(),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      controller: chatController.scrollController,
                      itemCount: snapshot.data != null
                          ? snapshot.data!.docs.length
                          : 0,
                      physics: ScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (_, index) {
                        QueryDocumentSnapshot message =
                            snapshot.data!.docs[index];
                        Timestamp time = message['time'];
                        String content = message['content'];
                        DateTime date = time.toDate();
                        String sender = message['sender'];
                        String receiver = message['receiver'];
                        String category = message['category'];
                        if ((chatController
                                        .compatibleUserList[
                                            chatController.currIndex.value]
                                        .user!
                                        .phoneNumber ==
                                    sender &&
                                signInController.user.phoneNumber ==
                                    receiver) ||
                            (chatController
                                        .compatibleUserList[
                                            chatController.currIndex.value]
                                        .user!
                                        .phoneNumber ==
                                    receiver &&
                                signInController.user.phoneNumber == sender)) {
                          if (index < minIndex) minIndex = index;

                          if (signInController.user.phoneNumber == sender) {
                            return ListTile(
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(left: 150.w),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.h,
                                      horizontal: 8.w,
                                    ),
                                    decoration: BoxDecoration(
                                      color: category.contains("Call")
                                          ? AppColors.receive
                                          : category == "image" ||
                                                  category == "video"
                                              ? AppColors.transparent
                                              : AppColors.send,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(20.r),
                                        topRight: Radius.circular(30.r),
                                        bottomLeft: Radius.circular(20.r),
                                      ),
                                    ),
                                    child: category == 'message'
                                        ? Text(
                                            content,
                                            style: CustomTextStyle.messageStyle(
                                                AppColors.white),
                                            textAlign: TextAlign.start,
                                          )
                                        : category == "image" ||
                                                category == "video"
                                            ? category == "image"
                                                ? CachedNetworkImage(
                                                    imageUrl: content,
                                                    imageBuilder: (context,
                                                        imageProvider) {
                                                      return Image(
                                                        image: imageProvider,
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                    placeholder:
                                                        (context, url) {
                                                      return CircularProgressIndicator();
                                                    },
                                                  )
                                                : VideoPlayerWidget(
                                                    url: content)
                                            : content.contains('accepted')
                                                ? ListTile(
                                                    leading: Container(
                                                      padding:
                                                          EdgeInsets.all(8.sp),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: AppColors
                                                            .thirdColor,
                                                      ),
                                                      child: category ==
                                                              'videoCall'
                                                          ? Icon(
                                                              Icons.videocam,
                                                              color: AppColors
                                                                  .white,
                                                              size: 50.sp,
                                                            )
                                                          : Icon(
                                                              Icons.call,
                                                              color: AppColors
                                                                  .white,
                                                              size: 50.sp,
                                                            ),
                                                    ),
                                                    title: Text(
                                                      category == 'videoCall'
                                                          ? 'Video Call'
                                                          : 'Audio Call',
                                                      style: CustomTextStyle
                                                          .messageCallStyle(
                                                              AppColors.black),
                                                    ),
                                                    subtitle: Text(content
                                                        .split('accepted')[1]),
                                                  )
                                                : ListTile(
                                                    leading: category ==
                                                            'videoCall'
                                                        ? Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    8.sp),
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color:
                                                                  AppColors.red,
                                                            ),
                                                            child: Icon(
                                                              Icons
                                                                  .videocam_off,
                                                              color: AppColors
                                                                  .white,
                                                              size: 50.sp,
                                                            ),
                                                          )
                                                        : Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    8.sp),
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color:
                                                                  AppColors.red,
                                                            ),
                                                            child: Icon(
                                                              Icons
                                                                  .phone_missed_rounded,
                                                              color: AppColors
                                                                  .white,
                                                              size: 50.sp,
                                                            ),
                                                          ),
                                                    title: Text(
                                                      category == 'videoCall'
                                                          ? 'Missed Video Call'
                                                          : 'Missed Audio Call',
                                                      style: CustomTextStyle
                                                          .messageCallStyle(
                                                              AppColors.black),
                                                    ),
                                                  ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                TimeFormat(date.hour.toString()) +
                                    ':' +
                                    TimeFormat(date.minute.toString()),
                                textAlign: TextAlign.end,
                              ),
                            );
                          } else if (chatController
                                  .compatibleUserList[
                                      chatController.currIndex.value]
                                  .user!
                                  .phoneNumber ==
                              sender) {
                            if (chatController.reportMessages
                                    .contains(content) ==
                                false)
                              chatController.reportMessages.add(content);

                            if (index == minIndex) {
                              chatController.UpdateLastestMessgage(content);
                            }
                            return ListTile(
                              leading: Container(
                                height: 80.h,
                                width: 80.w,
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    chatController
                                        .compatibleUserList[
                                            chatController.currIndex.value]
                                        .user!
                                        .images
                                        .first,
                                  ),
                                ),
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(right: 140.w),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.h,
                                      horizontal: 8.w,
                                    ),
                                    child: category == 'message'
                                        ? Text(
                                            content,
                                            style: CustomTextStyle.messageStyle(
                                                AppColors.black),
                                            textAlign: TextAlign.start,
                                          )
                                        : category == "image" ||
                                                category == "video"
                                            ? category == "image"
                                                ? CachedNetworkImage(
                                                    imageUrl: content,
                                                    imageBuilder: (context,
                                                        imageProvider) {
                                                      return Image(
                                                        image: imageProvider,
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                    placeholder:
                                                        (context, url) {
                                                      return CircularProgressIndicator();
                                                    },
                                                  )
                                                : VideoPlayerWidget(
                                                    url: content)
                                            : content.contains('accepted')
                                                ? ListTile(
                                                    leading: Container(
                                                      padding:
                                                          EdgeInsets.all(8.sp),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: AppColors
                                                            .thirdColor,
                                                      ),
                                                      child: category ==
                                                              'videoCall'
                                                          ? Icon(
                                                              Icons.videocam,
                                                              color: AppColors
                                                                  .white,
                                                              size: 50.sp,
                                                            )
                                                          : Icon(
                                                              Icons.call,
                                                              color: AppColors
                                                                  .white,
                                                              size: 50.sp,
                                                            ),
                                                    ),
                                                    title: Text(
                                                      category == 'videoCall'
                                                          ? 'Video Call'
                                                          : 'Audio Call',
                                                      style: CustomTextStyle
                                                          .messageCallStyle(
                                                              AppColors.black),
                                                    ),
                                                    subtitle: Text(content
                                                        .split('accepted')[1]),
                                                  )
                                                : ListTile(
                                                    leading: Container(
                                                      padding:
                                                          EdgeInsets.all(8.sp),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: AppColors.red,
                                                      ),
                                                      child: category ==
                                                              'videoCall'
                                                          ? Icon(
                                                              Icons
                                                                  .videocam_off,
                                                              color: AppColors
                                                                  .white,
                                                              size: 50.sp,
                                                            )
                                                          : Icon(
                                                              Icons
                                                                  .phone_missed_rounded,
                                                              color: AppColors
                                                                  .white,
                                                              size: 50.sp,
                                                            ),
                                                    ),
                                                    title: Text(
                                                      category == 'videoCall'
                                                          ? 'Missed Video Call'
                                                          : 'Missed Audio Call',
                                                      style: CustomTextStyle
                                                          .messageCallStyle(
                                                              AppColors.black),
                                                    ),
                                                  ),
                                    decoration: BoxDecoration(
                                      color: category == "image" ||
                                              category == "video"
                                          ? AppColors.transparent
                                          : AppColors.receive,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(20.r),
                                        topRight: Radius.circular(30.r),
                                        bottomRight: Radius.circular(20.r),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                TimeFormat(date.hour.toString()) +
                                    ':' +
                                    TimeFormat(date.minute.toString()),
                                textAlign: TextAlign.start,
                              ),
                            );
                          }
                        } else {
                          return Container();
                        }
                      },
                    );
                  },
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Obx(
                    () => chatController.isBlock.value == true ||
                            chatController.block.value == true
                        ? (chatController.block.value == true
                            ? Center(
                                child: Container(
                                  padding: EdgeInsets.only(top: 20.h),
                                  decoration: BoxDecoration(
                                      border: Border(
                                          top: BorderSide(width: 0.5.sp))),
                                  child: Column(
                                    children: [
                                      Text(
                                        'You have blocked ${chatController.compatibleUserList[chatController.currIndex.value].user!.name}',
                                        style: CustomTextStyle
                                            .communityRulesHeader(
                                                AppColors.thirdColor),
                                      ),
                                      Text(
                                        'You cannot message the person in this chat, nor receive messages or calls from them.',
                                        style: CustomTextStyle.h3(
                                            AppColors.disabledBackground),
                                        textAlign: TextAlign.center,
                                      ),
                                      UnblockButton(
                                          databaseService: databaseService,
                                          chatController: chatController),
                                    ],
                                  ),
                                ),
                              )
                            : Center(
                                child: Container(
                                    width: 720.w,
                                    margin: EdgeInsets.only(bottom: 20.h),
                                    padding: EdgeInsets.only(
                                        top: 16.h, bottom: 16.h),
                                    decoration: BoxDecoration(
                                        border: Border(
                                            top: BorderSide(
                                                width: 1.0,
                                                color: AppColors
                                                    .disabledBackground))),
                                    child: Text(
                                      'You have been blocked',
                                      style: CustomTextStyle.messageStyle(
                                        AppColors.thirdColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    )),
                              ))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Obx(() => chatController.isFocus.value == false
                                  ? TakePhotoButton()
                                  : Container()),
                              Obx(() => chatController.isFocus.value == false
                                  ? PickPhotoButton()
                                  : Container()),
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(
                                    left: 20.w,
                                    bottom: 40.h,
                                  ),
                                  child: Column(
                                    children: [
                                      Obx(
                                        () => chatController.suggestRep.value !=
                                                ''
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      vertical: 8.h,
                                                      horizontal: 8.w,
                                                    ),
                                                    margin: EdgeInsets.only(
                                                        right: 50.w,
                                                        bottom: 20.h),
                                                    child: Text(
                                                      '💡'
                                                      '${chatController.suggestRep.value}',
                                                      style: CustomTextStyle
                                                          .messageStyle(
                                                              AppColors.white),
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.send,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(
                                                                20.r),
                                                        topRight:
                                                            Radius.circular(
                                                                30.r),
                                                        bottomLeft:
                                                            Radius.circular(
                                                                20.r),
                                                      ),
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          chatController
                                                                  .messageController
                                                                  .text =
                                                              chatController
                                                                  .suggestRep
                                                                  .value;
                                                          chatController
                                                              .UpdateSuggestRep(
                                                                  '');
                                                        },
                                                        child: Text('Apply'),
                                                      ),
                                                      Text(' | '),
                                                      GestureDetector(
                                                        onTap: () {
                                                          chatController
                                                              .UpdateSuggestRep(
                                                                  '');
                                                        },
                                                        child: Text('Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              )
                                            : Container(),
                                      ),
                                      AddMessageField(
                                          chatController: chatController),
                                    ],
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.transparent,
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(
                                    left: 10.w, right: 20.w, bottom: 40.h),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: SendMessageButton(),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
