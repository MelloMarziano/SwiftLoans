import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/responsive.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/responsive_page.dart';
import 'home_controller.dart';
import 'widgets/cashflow_card.dart';
import 'widgets/home_header.dart';
import 'widgets/portfolio_card.dart';
import 'widgets/portfolio_status_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/stats_row.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 960;
        final mobile = constraints.maxWidth < 600;
        final gap = mobile ? 14.0 : 20.0;

        return ResponsivePage(
          children: [
            const HomeHeader().entrance(0),
            SizedBox(height: mobile ? 16 : 24),
            const PortfolioCard().entrance(1),
            SizedBox(height: mobile ? 20 : 28),
            Text(
              'Accesos rápidos',
              style: TextStyle(
                fontSize: context.sized(17, 20),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: mobile ? 10 : 14),
            const QuickActions().entrance(2),
            SizedBox(height: mobile ? 10 : 14),
            const StatsRow().entrance(3),
            SizedBox(height: gap),
            if (twoColumns)
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: PortfolioStatusCard()),
                  SizedBox(width: 20),
                  Expanded(child: CashflowCard()),
                ],
              ).entrance(4)
            else ...[
              const PortfolioStatusCard().entrance(4),
              SizedBox(height: gap),
              const CashflowCard().entrance(5),
            ],
          ],
        );
      },
    );
  }
}
