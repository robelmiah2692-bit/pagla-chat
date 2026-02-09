@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("পাগলা গ্রুপ কল"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isCalling ? Icons.call_end : Icons.call, 
                color: _isCalling ? Colors.red : Colors.green, size: 30),
            onPressed: () async {
              if (_isCalling) {
                await _engine.leaveChannel();
              } else {
                await _engine.joinChannel(token: '', channelId: "pagla_room", uid: 0, 
                  options: const ChannelMediaOptions(clientRoleType: ClientRoleType.clientRoleBroadcaster, 
                  channelProfile: ChannelProfileType.channelProfileCommunication));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // কল এরিয়া: ১০ জন পর্যন্ত ইউজারকে গ্রিড আকারে দেখাবে
          if (_isCalling)
            Container(
              height: 250, // গ্রিডের জন্য উচ্চতা বাড়ানো হয়েছে
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1)),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // এক লাইনে ৪ জন করে বসবে
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: _remoteUsers.length + 1, // আপনি + বাকি সবাই
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _userIcon("আপনি", Colors.blue);
                  } else {
                    return _userIcon("ইউজার ${_remoteUsers[index - 1]}", Colors.green);
                  }
                },
              ),
            ),
          
          // চ্যাট মেসেজ এরিয়া
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => ListTile(
                title: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.indigo[100], 
                      borderRadius: BorderRadius.circular(15)),
                    child: Text(_messages[index]),
                  ),
                ),
              ),
            ),
          ),
          
          // মেসেজ টাইপ বার
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "মেসেজ লিখুন...", 
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.indigo),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      setState(() { _messages.add(_controller.text); _controller.clear(); });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ইউজার আইকন ডিজাইন
  Widget _userIcon(String name, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 25, 
          backgroundColor: color, 
          child: const Icon(Icons.mic, color: Colors.white, size: 24)
        ),
        const SizedBox(height: 4),
        Text(
          name, 
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
