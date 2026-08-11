import 'package:flutter/material.dart';
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

  // --- ตำแหน่งลูกโป่งแชท: ลากได้อิสระ แล้วสแนปชิดขอบซ้าย/ขวาที่ใกล้ที่สุดตอนปล่อยนิ้ว ---
  static const double _bubbleSize = 56;
  static const double _edgeMargin = 16;
  static const double _minBottom = 90; // เผื่อพื้นที่แถบเมนูล่าง/ปุ่มวิ่งตรงกลาง

  bool _stickRight = true; // ด้านที่ลูกโป่ง "จอด" อยู่ตอนไม่ได้ลาก
  double _bottom = _minBottom; // ระยะจากขอบล่างจอ ตอนไม่ได้ลาก (ผู้ใช้เลือกเองได้)

  bool _dragging = false;
  double _dragLeft = 0; // ตำแหน่งซ้ายขณะกำลังลาก (อัปเดตตามนิ้วแบบเรียลไทม์)
  double _dragBottom = _minBottom;

  @override void dispose() { _input.dispose(); _scroll.dispose(); super.dispose(); }

  void _onPanStart(DragStartDetails details, double screenWidth, double currentWidth) {
    setState(() {
      _dragging = true;
      _dragLeft = _stickRight ? screenWidth - currentWidth - _edgeMargin : _edgeMargin;
      _dragBottom = _bottom;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, double screenWidth, double maxBottom) {
    setState(() {
      _dragLeft = (_dragLeft + details.delta.dx).clamp(0.0, screenWidth - _bubbleSize).toDouble();
      _dragBottom = (_dragBottom - details.delta.dy).clamp(_minBottom, maxBottom).toDouble();
    });
  }

  void _onPanEnd(DragEndDetails details, double screenWidth) {
    setState(() {
      _dragging = false;
      // สแนปเข้าขอบที่ใกล้ที่สุด (ซ้าย/ขวา) โดยยังอยู่ที่ความสูงเดิมที่วางไว้
      _stickRight = (_dragLeft + _bubbleSize / 2) > screenWidth / 2;
      _bottom = _dragBottom;
    });
  }

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
    final topSafe = MediaQuery.of(context).padding.top + 16;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    final width = _open ? (size.width > 600 ? 380.0 : size.width - 32) : _bubbleSize;
    final desiredHeight = _open ? (size.height * .6).clamp(380, 560).toDouble() : _bubbleSize;

    final parkedBottom = _dragging ? _dragBottom : _bottom;
    // ตอนแผงแชทเปิดอยู่แล้วคีย์บอร์ดผุดขึ้นมา ให้แผงชิดคีย์บอร์ดตรงๆ เสมอ
    // (เดิมใช้ math.max เทียบกับตำแหน่งที่จอดไว้ก่อนหน้า ทำให้ถ้าเคยลากไปจอดสูงไว้
    // พอคีย์บอร์ดขึ้นแผงจะค้างอยู่ตำแหน่งสูงเดิม เกิดช่องว่างเห็นเนื้อหาหลังบ้านแทรกอยู่)
    final requestedBottom = (_open && keyboardInset > 0)
        ? keyboardInset + 12
        : parkedBottom;

    // ย่อความสูงแผงลงถ้าพื้นที่เหลือไม่พอ (กันแผงทะลุขอบบนตอนคีย์บอร์ดกินพื้นที่จอเยอะ)
    final maxHeightForRequestedBottom = size.height - topSafe - requestedBottom;
    final height = _open
        ? desiredHeight.clamp(220.0, maxHeightForRequestedBottom > 220 ? maxHeightForRequestedBottom : 220.0).toDouble()
        : _bubbleSize;

    // ขอบเขตแนวตั้งที่ยอมให้อยู่ได้ (คำนวณใหม่ทุกครั้งตามความสูงปัจจุบัน กันแผงแชทโป่งพ้นจอบนตอนเปิด)
    final maxBottom = size.height - topSafe - height;
    final effectiveBottom = requestedBottom
        .clamp(_minBottom, maxBottom < _minBottom ? _minBottom : maxBottom)
        .toDouble();
    final effectiveLeft = _dragging
        ? _dragLeft
        : (_stickRight ? size.width - width - _edgeMargin : _edgeMargin);

    return AnimatedPositioned(
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      left: effectiveLeft,
      bottom: effectiveBottom,
      child: GestureDetector(
        onPanStart: _open ? null : (d) => _onPanStart(d, size.width, width),
        onPanUpdate: _open ? null : (d) => _onPanUpdate(d, size.width, maxBottom < _minBottom ? _minBottom : maxBottom),
        onPanEnd: _open ? null : (d) => _onPanEnd(d, size.width),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_open ? 22 : 28),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn,
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(_open ? 22 : 28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_open ? 22 : 28),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _open
                    ? _panel(key: const ValueKey('chat-panel'))
                    : IconButton(
                        key: const ValueKey('chat-icon'),
                        onPressed: () => setState(() => _open = true),
                        icon: Icon(Icons.smart_toy_rounded, color: AppColors.primary),
                        tooltip: 'เปิด AI Coach',
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel({Key? key}) => Column(
        key: key,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_alt_rounded, color: Colors.white),
                const SizedBox(width: 9),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Coach', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      Text('ผู้ช่วยฝึกวิ่งของคุณ', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _open = false),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
      Expanded(child: ListView.builder(controller: _scroll, padding: EdgeInsets.all(12), itemCount: _messages.length + (_sending ? 1 : 0), itemBuilder: (_, i) { if (i == _messages.length) return Padding(padding: EdgeInsets.all(8), child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))); final m = _messages[i]; return Align(alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9), constraints: BoxConstraints(maxWidth: 285), decoration: BoxDecoration(color: m.isUser ? AppColors.primary : AppColors.background, borderRadius: BorderRadius.circular(14)), child: Text(m.text, style: TextStyle(fontSize: 13, height: 1.35, color: m.isUser ? Colors.white : AppColors.textPrimary)))); })),
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
            icon: Icon(Icons.send_rounded, color: AppColors.primary),
          ),
        ],
      ),
    ),
  ]);
}
