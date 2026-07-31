import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/coach_service.dart';
import '../theme/app_theme.dart';

/// Floating AI Coach chat available without leaving the current screen.
class CoachChatPopup extends StatefulWidget {
  const CoachChatPopup({super.key});
  @override State<CoachChatPopup> createState() => _CoachChatPopupState();
}

class _CoachChatPopupState extends State<CoachChatPopup> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [ChatMessage(text: 'สวัสดีครับ 👋 ผมคือ AI Coach มีอะไรให้ช่วยเรื่องการวิ่งหรือการฝึกบ้างครับ', isUser: false)];
  bool _open = false;
  bool _sending = false;

  @override void dispose() { _input.dispose(); _scroll.dispose(); super.dispose(); }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) { if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut); });

  Future<void> _send() async {
    final message = _input.text.trim();
    if (message.isEmpty || _sending) return;
    setState(() { _messages.add(ChatMessage(text: message, isUser: true)); _sending = true; });
    _input.clear(); _scrollDown();
    final historyStart = _messages.length > 11 ? _messages.length - 11 : 0;
    final history = _messages.length > 1
        ? _messages.sublist(historyStart, _messages.length - 1)
        : <ChatMessage>[];
    final reply = await CoachService.instance.sendMessage(message: message, recentHistory: history);
    if (!mounted) return;
    setState(() { _messages.add(ChatMessage(text: reply.reply, isUser: false)); _sending = false; });
    _scrollDown();
  }

  @override Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      right: 16, bottom: 90,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_open ? 22 : 28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
          width: _open ? (size.width > 600 ? 380 : size.width - 32) : 56,
          height: _open ? (size.height * .6).clamp(380, 560).toDouble() : 56,
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(_open ? 22 : 28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 24, offset: const Offset(0, 8))]),
          child: _open ? _panel() : IconButton(onPressed: () => setState(() => _open = true), icon: const Icon(Icons.smart_toy_rounded, color: AppColors.primary), tooltip: 'เปิด AI Coach'),
        ),
      ),
    );
  }

  Widget _panel() => Column(children: [
    Container(padding: const EdgeInsets.fromLTRB(16, 12, 8, 12), decoration: BoxDecoration(gradient: const LinearGradient(colors: AppColors.primaryGradient), borderRadius: const BorderRadius.vertical(top: Radius.circular(22))), child: Row(children: [const Icon(Icons.psychology_alt_rounded, color: Colors.white), const SizedBox(width: 9), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('AI Coach', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), Text('ผู้ช่วยฝึกวิ่งของคุณ', style: TextStyle(color: Colors.white70, fontSize: 11))])), IconButton(onPressed: () => setState(() => _open = false), icon: const Icon(Icons.close_rounded, color: Colors.white))])),
      Expanded(child: ListView.builder(controller: _scroll, padding: const EdgeInsets.all(12), itemCount: _messages.length + (_sending ? 1 : 0), itemBuilder: (_, i) { if (i == _messages.length) return const Padding(padding: EdgeInsets.all(8), child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))); final m = _messages[i]; return Align(alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), constraints: const BoxConstraints(maxWidth: 285), decoration: BoxDecoration(color: m.isUser ? AppColors.primary : AppColors.background, borderRadius: BorderRadius.circular(14)), child: Text(m.text, style: TextStyle(fontSize: 13, height: 1.35, color: m.isUser ? Colors.white : AppColors.textPrimary)))); })),
    Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              onSubmitted: (_) => _send(),
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                isDense: true,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: _sending ? null : _send,
            icon: const Icon(Icons.send_rounded, color: AppColors.primary),
          ),
        ],
      ),
    ),
  ]);
}
