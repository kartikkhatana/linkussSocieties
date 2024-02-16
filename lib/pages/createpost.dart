import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linkuss/providers/basicProviders.dart';
import 'package:linkuss/utils/showSnackbar.dart';
import 'package:uuid/uuid.dart';

import '../widgets/buttons.dart';
import '../widgets/textfields.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final descC = TextEditingController();
  final titleC = TextEditingController();
  final imageProvider = StateProvider.autoDispose((ref) => "");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back_ios)),
                  Text(
                    "Create Post",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  String opt = "";
                  await showOptions().then((value) {
                    if (value != null) {
                      opt = value;
                      selectImage(opt);
                    }
                  });
                },
                child: Consumer(
                  builder: (context, ref, child) {
                    return Container(
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(20)),
                      child: ref.watch(imageProvider) != ""
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                File(ref.watch(imageProvider)),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container();
                                },
                              ),
                            )
                          : Center(
                              child: Text("Add Image"),
                            ),
                      height: 200,
                      width: MediaQuery.of(context).size.width,
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Align(
                      alignment: Alignment.center,
                      child: primaryTextField(
                          controller: titleC,
                          hint: "Title",
                          prefix: Icon(Icons.email)))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Align(
                      alignment: Alignment.center,
                      child: primaryTextField(
                        controller: descC,
                        min: 3,
                        max: 10,
                        hint: "Description",
                      ))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Align(
                      alignment: Alignment.center,
                      child:
                          primaryButton(MediaQuery.of(context).size.width / 2,
                              callback: () async {
                        if (titleC.text.isNotEmpty &&
                            descC.text.isNotEmpty &&
                            ref.read(imageProvider).isNotEmpty) {
                          await createPost();

                          Navigator.pop(context);
                        } else {
                          showSnackBar(
                              context, "Please fill all the above fields");
                        }
                      }, title: "Create Post"))),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> showOptions() async {
    return showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "Select Option",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context, "camera");
                      },
                      child: Container(
                        child: Column(
                          children: [
                            Icon(Icons.camera_alt),
                            SizedBox(height: 10),
                            Text("Camera")
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context, "photos");
                      },
                      child: Container(
                        child: Column(
                          children: [
                            Icon(Icons.photo_album),
                            SizedBox(height: 10),
                            Text("Photos")
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    // await ;
  }

  Future<XFile?> selectImage(String opt) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = opt == "camera"
          ? await picker.pickImage(source: ImageSource.camera)
          : await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        ref.read(imageProvider.notifier).state = image.path;
      }
      print(ref.read(imageProvider));
    } catch (e) {
      showSnackBar(context, "Something went wrong while selecting image");
      print("Something went wrong" + e.toString());
    }
  }

  Future<String?> uploadImage() async {
    try {
      final storageRef = FirebaseStorage.instance.ref();

      final postsRef = storageRef.child(
          "posts/${FirebaseAuth.instance.currentUser!.uid}-${Uuid().v4()}.jpg");

      if (ref.read(imageProvider) != "") {
        try {
          await postsRef.putFile(File(ref.read(imageProvider)));
          String url = await postsRef.getDownloadURL();
          return url;
        } on FirebaseException catch (e) {
          print(e);
        }
      }
    } catch (e) {
      showSnackBar(context, "Something went wrong while uploading image");
      print("Something went wrong" + e.toString());
    }
  }

  Future createPost() async {
    ref.read(isLoading.notifier).state = true;
    try {
      String? url = await uploadImage();
      if (url == null) throw Future<Error>;
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      DocumentReference ref =
          await FirebaseFirestore.instance.collection("Posts").add({
        "commentCount": 0,
        "description": descC.text,
        "title": titleC.text,
        "postBy": FirebaseAuth.instance.currentUser!.uid,
        "timestamp": timestamp,
        "likedBy": [],
        "likeCount": 0,
        "filter": "USICT",
        "image": url,
      });
      await ref.update({"UID": ref.id});
      showSnackBar(context, "Post Successfully Created");
    } catch (e) {
      showSnackBar(context, "Something went wrong while creating post");
      print("Something went wrong");
    }
    ref.read(isLoading.notifier).state = false;
  }
}
