import 'package:flutter/material.dart';

class BuscadorDialog extends StatefulWidget {
  final List<String> items;
  final Function(String) onSelected;

  const BuscadorDialog(
      {super.key, required this.items, required this.onSelected});

  @override
  State createState() => _BuscadorDialogState();
}

class _BuscadorDialogState extends State<BuscadorDialog> {
  List<String> _filteredItems = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filter(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(6), // 👈 esquinas suaves estilo Windows
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.25,
        vertical: size.height * 0.25,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade200, // 👈 barra superior estilo Windows
              child: Row(
                children: const [
                  Icon(Icons.search, color: Colors.black54),
                  SizedBox(width: 8),
                  Text("Buscar elemento",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Escriba para filtrar...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onChanged: _filter,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return InkWell(
                    onTap: () {
                      widget.onSelected(item);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(item,
                          style: const TextStyle(color: Colors.black87)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
