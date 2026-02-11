import 'package:flutter/material.dart';
import 'package:pagla_app/core/constants.dart';
import 'package:pagla_app/widgets/seat_widget.dart';
import 'package:pagla_app/widgets/action_menu.dart';

class VoiceRoomScreen extends StatefulWidget {
  const VoiceRoomScreen({super.key});

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  void _openActionMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RoomActionMenu(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppConstants.primaryColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ভিডিও/ইউটিউব উইন্ডো
              Container(
                height: 200,
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.red, size: 50)),
              ),
              // ২০টি সিট
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: 20,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) => SeatWidget(index: index),
                ),
              ),
              // নিচের কন্ট্রোল বার
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(25)),
                        child: const TextField(decoration: InputDecoration(hintText: "বলুন কিছু...", border: InputBorder.none)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppConstants.accentColor, size: 35),
                      onPressed: _openActionMenu,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
