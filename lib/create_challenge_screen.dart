import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Provider/chat_provider.dart';
import 'Model/model.dart';

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Core Setup
  final _idController = TextEditingController(text: 'ask_for_date');
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _categoriesController = TextEditingController();
  String _difficulty = 'beginner'; // beginner, intermediate, advance
  final _durationController = TextEditingController(text: '5');

  // Rules
  final _timeLimitController = TextEditingController(text: '300');
  final _maxTurnsController = TextEditingController(text: '12');
  final _hintFreqController = TextEditingController(text: 'high');

  // Difficulty Modifiers
  double _resistance = 0.2;
  double _trust = 0.4;
  double _signal = 0.3;
  double _mistake = 0.9;
  double _skepticism = 0.1;
  double _openness = 0.9;

  // Context Settings
  final _ctxSettingController = TextEditingController();
  final _ctxLocationController = TextEditingController();
  final _ctxTimeController = TextEditingController();
  final _ctxMoodController = TextEditingController();
  final _ctxPlatformController = TextEditingController(text: 'Instagram DMs');
  final _ctxGoalController = TextEditingController();
  final _ctxStakesController = TextEditingController();
  final _ctxSoundsController = TextEditingController();
  final _ctxVisualsController = TextEditingController();

  // Persona Assignment
  Persona? _selectedPersona;
  bool _isSaving = false;

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _descController.dispose();
    _shortDescController.dispose();
    _categoriesController.dispose();
    _durationController.dispose();
    _timeLimitController.dispose();
    _maxTurnsController.dispose();
    _hintFreqController.dispose();
    _ctxSettingController.dispose();
    _ctxLocationController.dispose();
    _ctxTimeController.dispose();
    _ctxMoodController.dispose();
    _ctxPlatformController.dispose();
    _ctxGoalController.dispose();
    _ctxStakesController.dispose();
    _ctxSoundsController.dispose();
    _ctxVisualsController.dispose();
    super.dispose();
  }

  List<String> _cleanList(String text) {
    if (text.trim().isEmpty) return [];
    return text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final payload = {
      'id': _idController.text.trim(),
      'title': _titleController.text.trim(),
      'subtitle': _subtitleController.text.trim(),
      'description': _descController.text.trim(),
      'short_description': _shortDescController.text.trim(),
      'categories': _cleanList(_categoriesController.text),
      'suggested_personas': _selectedPersona != null ? [_selectedPersona!.id] : [],
      'difficulty': _difficulty,
      'difficulty_settings': {
        'resistance_level': _resistance,
        'required_trust_score': _trust,
        'positive_signal_threshold': _signal,
        'mistake_tolerance': _mistake,
        'hint_frequency': _hintFreqController.text.trim(),
        'skepticism_level': _skepticism,
        'emotional_openness': _openness,
      },
      'estimated_duration_minutes': int.tryParse(_durationController.text.trim()) ?? 5,
      'challenge_rules': {
        'time_limit_seconds': int.tryParse(_timeLimitController.text.trim()) ?? 300,
        'max_turns': int.tryParse(_maxTurnsController.text.trim()) ?? 12,
        'allow_pause': false,
        'auto_end_on_success': true,
        'auto_end_on_failure': true,
      },
      'image_url': '',
      'selected_persona_id': _selectedPersona?.id,
      'context': {
        'challenge_id': _idController.text.trim(),
        'setting': _ctxSettingController.text.trim(),
        'environment': {
          'location': _ctxLocationController.text.trim(),
          'time_of_day': _ctxTimeController.text.trim(),
          'ambience': _ctxMoodController.text.trim(),
          'background_sounds': _cleanList(_ctxSoundsController.text),
          'visual_details': _cleanList(_ctxVisualsController.text),
          'mood': _ctxMoodController.text.trim(),
        },
        'goal': _ctxGoalController.text.trim(),
        'stakes': _ctxStakesController.text.trim(),
        'platform': _ctxPlatformController.text.trim(),
      }
    };

    try {
      final provider = context.read<ChatProvider>();
      await provider.createChallenge(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create challenge: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white60,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFieldCard({required List<Widget> children, required Color cardColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSliderGroup({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          activeColor: accentColor,
          inactiveColor: Colors.white12,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final cardColor = theme.colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Challenge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Core Setup'),
                _buildFieldCard(
                  cardColor: cardColor,
                  children: [
                    TextFormField(
                      controller: _idController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Challenge ID',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a unique Challenge ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subtitleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Subtitle',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _shortDescController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Short Description',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Full Description',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _categoriesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Categories (Comma separated)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _difficulty,
                            dropdownColor: cardColor,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Difficulty',
                              labelStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: accentColor),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                              DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                              DropdownMenuItem(value: 'advance', child: Text('Advanced')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _difficulty = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Est. Minutes',
                              labelStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: accentColor),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                _buildSectionHeader('Rules & Engine Enforcements'),
                _buildFieldCard(
                  cardColor: cardColor,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _timeLimitController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Time Limit (Sec)',
                              labelStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: accentColor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxTurnsController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Max Turn Count',
                              labelStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: accentColor),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hintFreqController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Hint Frequency',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                    ),
                  ],
                ),
                
                _buildSectionHeader('Difficulty Modifiers (0.0 - 1.0)'),
                _buildFieldCard(
                  cardColor: cardColor,
                  children: [
                    _buildSliderGroup(
                      label: 'Resistance Level',
                      value: _resistance,
                      onChanged: (val) => setState(() => _resistance = val),
                      accentColor: accentColor,
                    ),
                    _buildSliderGroup(
                      label: 'Required Trust Score',
                      value: _trust,
                      onChanged: (val) => setState(() => _trust = val),
                      accentColor: accentColor,
                    ),
                    _buildSliderGroup(
                      label: 'Positive Signal Threshold',
                      value: _signal,
                      onChanged: (val) => setState(() => _signal = val),
                      accentColor: accentColor,
                    ),
                    _buildSliderGroup(
                      label: 'Mistake Tolerance',
                      value: _mistake,
                      onChanged: (val) => setState(() => _mistake = val),
                      accentColor: accentColor,
                    ),
                    _buildSliderGroup(
                      label: 'Skepticism Level',
                      value: _skepticism,
                      onChanged: (val) => setState(() => _skepticism = val),
                      accentColor: accentColor,
                    ),
                    _buildSliderGroup(
                      label: 'Emotional Openness',
                      value: _openness,
                      onChanged: (val) => setState(() => _openness = val),
                      accentColor: accentColor,
                    ),
                  ],
                ),
                
                _buildSectionHeader('Context & Environment Details'),
                _buildFieldCard(
                  cardColor: cardColor,
                  children: [
                    TextFormField(
                      controller: _ctxSettingController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Setting Synopsis',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ctxLocationController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Location',
                              labelStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: accentColor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _ctxTimeController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Time of Day',
                              labelStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: accentColor),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ctxMoodController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Ambience Mood',
                              labelStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: accentColor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _ctxPlatformController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Platform',
                              labelStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: accentColor),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ctxGoalController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Goal',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a goal';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ctxStakesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Stakes',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ctxSoundsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Background Sounds (Comma separated)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ctxVisualsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Visual Details (Comma separated)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                    ),
                  ],
                ),
                
                _buildSectionHeader('Persona Assignment'),
                Consumer<ChatProvider>(
                  builder: (context, provider, child) {
                    final personas = provider.allPersonas;
                    return _buildFieldCard(
                      cardColor: cardColor,
                      children: [
                        DropdownButtonFormField<Persona?>(
                          value: _selectedPersona,
                          dropdownColor: cardColor,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Assign Persona',
                            labelStyle: const TextStyle(color: Colors.white54),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: accentColor),
                            ),
                          ),
                          hint: const Text('Pick a persona', style: TextStyle(color: Colors.white30)),
                          items: [
                            const DropdownMenuItem<Persona?>(
                              value: null,
                              child: Text('None (Optional)'),
                            ),
                            ...personas.map((p) {
                              return DropdownMenuItem<Persona?>(
                                value: p,
                                child: Text(p.name),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPersona = value;
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text(
                            'Create Challenge',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
