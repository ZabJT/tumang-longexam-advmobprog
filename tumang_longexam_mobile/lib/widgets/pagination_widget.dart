import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final bool isLoading;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          _buildNavButton(
            icon: Icons.chevron_left,
            onPressed: currentPage > 1
                ? () => onPageChanged(currentPage - 1)
                : null,
            isEnabled: currentPage > 1,
          ),
          SizedBox(width: 8.w),

          // Page Numbers
          ..._buildPageNumbers(context),

          SizedBox(width: 8.w),

          // Next Button
          _buildNavButton(
            icon: Icons.chevron_right,
            onPressed: currentPage < totalPages
                ? () => onPageChanged(currentPage + 1)
                : null,
            isEnabled: currentPage < totalPages,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(BuildContext context) {
    List<Widget> pageNumbers = [];

    // Calculate the range of pages to show
    List<int> pagesToShow = _getPagesToShow();

    for (int page in pagesToShow) {
      pageNumbers.add(_buildPageButton(context, page));
      if (page != pagesToShow.last) {
        pageNumbers.add(SizedBox(width: 4.w));
      }
    }

    return pageNumbers;
  }

  List<int> _getPagesToShow() {
    List<int> pages = [];

    if (totalPages <= 5) {
      // Show all pages if total is 5 or less
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      // Calculate sliding window
      int startPage = _calculateStartPage();
      int endPage = _calculateEndPage(startPage);

      for (int i = startPage; i <= endPage; i++) {
        pages.add(i);
      }
    }

    return pages;
  }

  int _calculateStartPage() {
    if (currentPage <= 3) {
      return 1;
    } else if (currentPage >= totalPages - 2) {
      return totalPages - 4;
    } else {
      return currentPage - 2;
    }
  }

  int _calculateEndPage(int startPage) {
    return (startPage + 4).clamp(1, totalPages);
  }

  Widget _buildPageButton(BuildContext context, int page) {
    bool isCurrentPage = page == currentPage;

    return GestureDetector(
      onTap: isLoading ? null : () => onPageChanged(page),
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: isCurrentPage
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isCurrentPage
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Center(
          child: isLoading && isCurrentPage
              ? SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                )
              : Text(
                  page.toString(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: isCurrentPage
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isCurrentPage ? Colors.white : Colors.grey[700],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isEnabled ? Colors.grey[300]! : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20.sp,
          color: isEnabled ? Colors.grey[700] : Colors.grey[400],
        ),
      ),
    );
  }
}
