import 'package:flutter/material.dart';
import 'support_service.dart'; // নিশ্চিত করুন যে এই ফাইলটি তৈরি করেছেন

class HelpDeskPage extends StatelessWidget {
  const HelpDeskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pagla Chat Help Desk"),
        backgroundColor: const Color(0xFF0F0C29),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.support_agent, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "Hi! I am Gemini, your AI assistant.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "How can I help you today? Whether you have questions about security, account issues, or app features, I'm here to support you.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // হেল্প বাটন
            ElevatedButton.icon(
              onPressed: () async {
                // ১. সাপোর্ট সার্ভিস থেকে অটো রেসপন্স নেওয়া
                String response = await SupportService.getAutoResponse("");
                
                // ২. ইউজারের সামনে রেসপন্সটি দেখানো
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Help Desk Support"),
                    content: Text(response),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      )
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.support_agent),
              label: const Text("Get Support"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}