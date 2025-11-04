import 'package:flutter/material.dart';

class VoucherCard extends StatelessWidget {
  final String name;
  final String description;
  final int points;
  final String imageUrl;
  final Color themeColor;
  final bool showButton;
  final bool isUsed;
  final VoidCallback? onRedeem;

  const VoucherCard({
    super.key,
    required this.name,
    required this.description,
    required this.points,
    required this.imageUrl,
    required this.themeColor,
    this.showButton = true,
    this.isUsed = false,
    this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.3;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(bottom: 12),
        child: Card(
          elevation: 2,
          shadowColor: themeColor.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 50,
                          width: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.card_giftcard,
                          size: 50, color: Colors.grey),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "$points pts",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          showButton
                              ? ElevatedButton(
                                  onPressed: onRedeem,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    "Redeem",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : Text(
                                  isUsed ? "Used" : "Unused",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isUsed ? Colors.grey : themeColor,
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
