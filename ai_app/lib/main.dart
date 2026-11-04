import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const OpenRouterAiApp());
}

class OpenRouterAiApp extends StatelessWidget {
  const OpenRouterAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenRouter AI Chat (BYK)',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  // Bring Your Key state variable
  String _apiKey = '';

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  // Load saved API key from local storage
  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('openrouter_api_key') ?? '';
    });
    
    // If no key is found on startup, prompt the user to enter one
    if (_apiKey.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showApiKeyDialog(isInitialSetup: true);
      });
    }
  }

  // Save API key to local storage
  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openrouter_api_key', key);
    setState(() {
      _apiKey = key;
    });
  }

  // Dialog for entering/updating the Bring Your Key (BYK) token
  void _showApiKeyDialog({bool isInitialSetup = false}) {
    final TextEditingController keyController = TextEditingController(text: _apiKey);
    
    showDialog(
      context: context,
      barrierDismissible: !isInitialSetup,
      builder: (context) => AlertDialog(
        title: const Text('Bring Your Key (BYK)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please enter your OpenRouter API key to use this app. Your key is securely stored locally on your device.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'OpenRouter API Key',
                hintText: 'sk-or-v1-...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (!isInitialSetup)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          FilledButton(
            onPressed: () {
              final newKey = keyController.text.trim();
              if (newKey.isNotEmpty) {
                _saveApiKey(newKey);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API Key saved successfully!')),
                );
              }
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (_apiKey.isEmpty) {
      _showApiKeyDialog();
      return;
    }

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://github.com/flutter/flutter',
          'X-Title': 'Flutter Material 3 AI App',
        },
        body: jsonEncode({
          'model': 'openrouter/free',
          'messages': [
            {'role': 'user', 'content': text}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data['choices'][0]['message']['content'] ?? 'No response';
        setState(() {
          _messages.add(ChatMessage(text: reply.trim(), isUser: false));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
              text: 'Error [${response.statusCode}]: ${response.body}',
              isUser: false));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: 'Connection Exception: $e', isUser: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenRouter Assistant'),
        centerTitle: true,
        elevation: 2,
        backgroundColor: colorScheme.surfaceContainerHighest,
        actions: [
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: 'Manage API Key',
            onPressed: () => _showApiKeyDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 64, color: colorScheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            'How can I help you today?',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _apiKey.isEmpty 
                                ? 'Tap the key icon in the top right to add your OpenRouter API key.' 
                                : 'Ready to chat!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: msg.isUser ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20).copyWith(
                              bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(20),
                              bottomLeft: !msg.isUser ? const Radius.circular(0) : const Radius.circular(20),
                            ),
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color: msg.isUser ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: colorScheme.primary),
            ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              color: colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: _apiKey.isEmpty ? 'Set API key to chat...' : 'Ask anything...',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send_rounded),
                    iconSize: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

