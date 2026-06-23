import 'package:flutter/material.dart';
import 'Services/analytics_manager.dart';
import 'core/config/app_config.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsManager _analytics = AnalyticsManager();

  String _formatDuration(double seconds) {
    if (seconds <= 0) return "0s";
    final intSecs = seconds.round();
    final h = intSecs ~/ 3600;
    final m = (intSecs % 3600) ~/ 60;
    final s = intSecs % 60;
    if (h > 0) {
      return "${h}h ${m}m ${s}s";
    } else if (m > 0) {
      return "${m}m ${s}s";
    }
    return "${s}s";
  }

  String _maskCredential(String cred, int visibleChars) {
    if (cred.isEmpty) return "Not Configured";
    if (cred.length <= visibleChars) return cred;
    return '${cred.substring(0, visibleChars)}...${cred.substring(cred.length - visibleChars)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final accentColor = theme.colorScheme.primary;

    // Retrieve analytics metrics
    final double avgSessionTime = _analytics.getAverageAppSessionTime();
    final double totalTime = _analytics.totalDurationSeconds.toDouble();
    final int totalSessionsCount = _analytics.totalSessions;

    final mostPlayedPersona = _analytics.getMostPlayedPersona();
    final mostPlayedChallenge = _analytics.getMostPlayedChallenge();

    final chatDropOff = _analytics.getChatMidwayExitRate();
    final challengeDropOff = _analytics.getChallengeMidwayExitRate();

    // Verify GA4 connection parameters
    final isGA4Configured = AppConfig.gaMeasurementId.isNotEmpty &&
        AppConfig.gaMeasurementId != 'G-XXXXXXXXXX' &&
        AppConfig.gaApiSecret.isNotEmpty &&
        AppConfig.gaApiSecret != 'YOUR_API_SECRET';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'App Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. GA4 Status Badge Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isGA4Configured
                      ? [accentColor.withOpacity(0.15), Colors.black26]
                      : [Colors.orangeAccent.withOpacity(0.12), Colors.black26],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isGA4Configured ? accentColor.withOpacity(0.3) : Colors.orangeAccent.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isGA4Configured ? Icons.cloud_done : Icons.cloud_queue,
                    color: isGA4Configured ? accentColor : Colors.orangeAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGA4Configured ? 'Google Analytics Enabled' : 'Local Analytics Mode',
                          style: TextStyle(
                            color: isGA4Configured ? Colors.white : Colors.orangeAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isGA4Configured
                              ? 'Dispatched to ${AppConfig.gaMeasurementId}'
                              : 'Edit app_config.dart to configure GA4 variables.',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Section: App Engagement
            const Text(
              'APP ENGAGEMENT',
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
              ),
              children: [
                _buildMetricCard('Total Sessions', '$totalSessionsCount', Icons.restore, cardColor, accentColor),
                _buildMetricCard('Total App Time', _formatDuration(totalTime), Icons.timelapse, cardColor, accentColor),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.timer_outlined, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Average Session Time',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(avgSessionTime),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 3. Section: Top Preferences
            const Text(
              'USER PREFERENCES',
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            _buildPrefCard(
              'Most Played Persona',
              mostPlayedPersona?.key ?? 'No chats yet',
              mostPlayedPersona != null ? '${mostPlayedPersona.value} times played' : 'Start chatting to record metrics',
              Icons.forum,
              cardColor,
              accentColor,
            ),
            const SizedBox(height: 12),
            _buildPrefCard(
              'Most Played Challenge',
              mostPlayedChallenge?.key ?? 'No challenges yet',
              mostPlayedChallenge != null ? '${mostPlayedChallenge.value} times played' : 'Try challenge modes to record metrics',
              Icons.stars,
              cardColor,
              accentColor,
            ),
            const SizedBox(height: 28),

            // 4. Section: Drop-offs (Leaving midway)
            const Text(
              'SESSION RETENTION & DROP-OFFS',
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Midway Drop-off Rate',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Percentage of sessions exited before sending a message or completing the challenge.',
                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDropOffIndicator('Chats', chatDropOff, Colors.redAccent, theme),
                      _buildDropOffIndicator('Challenges', challengeDropOff, Colors.orangeAccent, theme),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 5. Section: Secrets / GA4 Configuration
            const Text(
              'GOOGLE ANALYTICS DETAILS',
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCredentialRow('Measurement ID', _maskCredential(AppConfig.gaMeasurementId, 4)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(color: Colors.white10, height: 1),
                  ),
                  _buildCredentialRow('API Secret Key', _maskCredential(AppConfig.gaApiSecret, 4)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(color: Colors.white10, height: 1),
                  ),
                  _buildCredentialRow('Device Client ID', _maskCredential(_analytics.clientId, 10)),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color cardColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Icon(icon, color: accentColor.withOpacity(0.6), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildPrefCard(String label, String title, String subtitle, IconData icon, Color cardColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropOffIndicator(String label, double value, Color color, ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          height: 70,
          width: 70,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 6,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  "${value.toStringAsFixed(0)}%",
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
