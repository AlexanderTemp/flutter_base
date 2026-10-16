import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_info.dart';
import 'app_logo.dart';
import 'surfaces.dart';
import 'workspace_controls.dart';

enum _Priority with AFDropDownMenuMixin {
  normal('Normal'), urgent('Urgente');
  const _Priority(this.label);
  @override
  final String label;
}

/// Ejemplos interactivos de los componentes que ya utiliza la plantilla.
class ComponentsPage extends StatefulWidget {
  const ComponentsPage({super.key});
  @override
  State<ComponentsPage> createState() => _ComponentsPageState();
}

class _ComponentsPageState extends State<ComponentsPage> {
  final _name = TextEditingController();
  final _field = GlobalKey<AFTextFieldState>();
  final _dropdown = AFPopoverController();
  final _popover = AFPopoverController();
  _Priority? _priority = _Priority.normal;
  bool _enabled = true;
  int _choice = 0;
  // Solo el texto de respuesta escucha este valor; pulsar un ejemplo no reconstruye la galería.
  final _action = ValueNotifier('Prueba un componente para ver su respuesta.');

  @override
  void dispose() {
    _name.dispose();
    _dropdown.dispose();
    _popover.dispose();
    _action.dispose();
    super.dispose();
  }

  void _respond(String message) => _action.value = message;

  void _validate() {
    if (_name.text.trim().isEmpty) {
      _field.currentState!.syncError(errorText: 'Escribe un nombre de ejemplo');
    } else {
      _field.currentState!.clearError();
      _respond('Formulario válido: ${_name.text.trim()}');
    }
  }

  Future<void> _dialog() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AFModal(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Diálogo de ejemplo', style: AppFlowyTheme.of(context).textStyle.heading4.enhanced(
              color: AppFlowyTheme.of(context).textColorScheme.primary)),
            const SizedBox(height: 12),
            const Text('AFModal comparte tema, bordes y tipografía con el resto de la app.'),
            const SizedBox(height: 24),
            Wrap(spacing: 8, runSpacing: 8, children: [
              AFOutlinedTextButton.normal(text: 'Cancelar', onTap: () => Navigator.pop(context, false)),
              AFFilledTextButton.primary(text: 'Confirmar', onTap: () => Navigator.pop(context, true)),
            ]),
          ]),
        ),
      ),
    );
    if (mounted) _respond(accepted == true ? 'Diálogo confirmado' : 'Diálogo cancelado');
  }

  Widget _section(String title, String source, List<Widget> children) {
    final t = AppFlowyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AfCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: t.textStyle.heading4.enhanced(color: t.textColorScheme.primary)),
          const SizedBox(height: 4),
          Text(source, style: t.textStyle.caption.standard(color: t.textColorScheme.secondary)),
          const SizedBox(height: 16),
          ...children,
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    return ListView(
      key: const PageStorageKey('components-gallery'),
      padding: const EdgeInsets.all(16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text('Componentes y diseños', style: t.textStyle.heading2.enhanced(color: t.textColorScheme.primary)),
        const SizedBox(height: 8),
        const Text('Plantilla interactiva. Cambia el tema y el tamaño de texto desde Ajustes para probar cada ejemplo.'),
        const SizedBox(height: 12),
        Semantics(liveRegion: true, child: ValueListenableBuilder<String>(
          valueListenable: _action,
          builder: (_, action, __) => Text(action,
            key: const ValueKey('component-feedback'),
            style: t.textStyle.body.enhanced(color: t.textColorScheme.action)))),
        const SizedBox(height: 20),
        _section('Marca, tipografía y etiquetas', 'AppInfo · AppFlowyTheme · AfPill', [
          Row(children: [
            const AppLogo(size: 56),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppInfo.name, style: t.textStyle.heading3.enhanced(color: t.textColorScheme.primary)),
              const Text('Desarrollado por ${AppInfo.developer}'),
            ])),
          ]),
          const SizedBox(height: 16),
          Text('Título de sección', style: t.textStyle.heading4.enhanced(color: t.textColorScheme.primary)),
          Text('Texto principal y jerarquía visual.', style: t.textStyle.body.standard(color: t.textColorScheme.primary)),
          Text('Texto secundario · contexto y ayuda.', style: t.textStyle.caption.standard(color: t.textColorScheme.secondary)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            const AfPill(text: 'Etiqueta'),
            AfPill(text: 'Información', bg: t.fillColorScheme.infoLight, fg: t.textColorScheme.info),
            AfPill(text: 'Advertencia', bg: t.fillColorScheme.warningLight, fg: t.textColorScheme.warning),
            AfPill(text: AppInfo.environment.name),
          ]),
        ]),
        _section('Botones y estados', 'AFFilledTextButton · AFOutlinedTextButton · AFGhostTextButton', [
          Wrap(spacing: 8, runSpacing: 8, children: [
            AFFilledTextButton.primary(text: 'Primario', onTap: () => _respond('Botón primario pulsado')),
            AFOutlinedTextButton.normal(text: 'Contorno', onTap: () => _respond('Botón de contorno pulsado')),
            AFGhostTextButton.primary(text: 'Fantasma', onTap: () => _respond('Botón fantasma pulsado')),
            AFFilledTextButton.destructive(text: 'Destructivo', onTap: () => _respond('Acción destructiva simulada')),
            AFFilledTextButton.disabled(text: 'Deshabilitado'),
            AFFilledIconTextButton.primary(text: 'Con icono', onTap: () => _respond('Botón con icono pulsado'),
              iconBuilder: (_, __, ___) => Icon(Icons.add, color: t.textColorScheme.onFill, size: 18)),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final size in AFButtonSize.values)
              AFOutlinedTextButton.normal(text: size.name.toUpperCase(), size: size,
                onTap: () => _respond('Tamaño ${size.name}')),
          ]),
        ]),
        _section('Selección e interruptores', 'WorkspaceChoice · WorkspaceToggle', [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < 3; i++)
              WorkspaceChoice(label: ['Lista', 'Tablero', 'Tarjetas'][i], selected: _choice == i,
                onTap: () => setState(() => _choice = i)),
          ]),
          const SizedBox(height: 12),
          WorkspaceToggle(label: 'Opción de ejemplo', description: 'Estado local de esta vista; respeta reducción de movimiento.',
            value: _enabled, onChanged: (value) => setState(() => _enabled = value)),
        ]),
        _section('Formulario y validación', 'AFTextField · AFTextFieldState', [
          Semantics(label: 'Nombre de ejemplo', child: AFTextField(
            key: _field, controller: _name, hintText: 'Nombre de ejemplo', maxLength: 80,
            onChanged: (_) => _field.currentState!.clearError(), onSubmitted: (_) => _validate())),
          const SizedBox(height: 12),
          Semantics(label: 'Campo de solo lectura', child: AFTextField(initialText: 'Solo lectura', readOnly: true)),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft,
            child: AFFilledTextButton.primary(text: 'Validar ejemplo', onTap: _validate)),
        ]),
        _section('Desplegable', 'AFDropDownMenu · AFPopoverController', [
          FocusableActionDetector(
            actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) { _dropdown.toggle(); return null; })},
            shortcuts: const {SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(), SingleActivator(LogicalKeyboardKey.space): ActivateIntent()},
            child: Semantics(label: 'Prioridad de ejemplo', button: true, onTap: _dropdown.toggle,
              child: AFDropDownMenu<_Priority>(controller: _dropdown, items: _Priority.values,
                selectedItems: [if (_priority != null) _priority!], emptyLabel: 'Elige prioridad',
                onSelected: (value) => setState(() => _priority = value))),
          ),
        ]),
        _section('Avatares y separadores', 'AFAvatar · AFDivider', [
          Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (final size in AFAvatarSize.values) AFAvatar(name: 'Ayni Code', size: size),
          ]),
          const AFDivider(spacing: 16),
          const Text('Los separadores usan el borde semántico del tema.'),
        ]),
        _section('Menús, popovers y diálogos', 'AFMenu · AFMenuItem · AFPopover · AFModal', [
          Wrap(spacing: 8, runSpacing: 8, children: [
            AFPopover(controller: _popover,
              popover: (_) => AFMenu(width: 220, children: [
                AFMenuItem(title: const Text('Editar ejemplo'), leading: const Icon(Icons.edit_outlined),
                  onTap: () { _popover.hide(); _respond('Editar seleccionado'); }),
                const AFDivider(spacing: 4),
                AFMenuItem(title: const Text('Duplicar ejemplo'), leading: const Icon(Icons.copy_outlined),
                  onTap: () { _popover.hide(); _respond('Duplicar seleccionado'); }),
              ]),
              child: AFOutlinedTextButton.normal(text: 'Abrir menú', onTap: _popover.toggle)),
            AFFilledTextButton.primary(text: 'Abrir diálogo', onTap: _dialog),
          ]),
        ]),
        _section('Diseño adaptable y estados', 'AfCard · LayoutBuilder · Flex · tokens semánticos', [
          LayoutBuilder(builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 640;
            return Flex(direction: horizontal ? Axis.horizontal : Axis.vertical,
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 2; i++) ...[
                  if (i > 0) SizedBox(width: horizontal ? 12 : 0, height: horizontal ? 0 : 12),
                  Flexible(flex: horizontal ? 1 : 0, child: AfCard(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(i == 0 ? 'Resumen' : 'Actividad', style: t.textStyle.body.enhanced(color: t.textColorScheme.primary)),
                      const SizedBox(height: 8),
                      Text(i == 0 ? '12 tareas de ejemplo' : '8 completadas · 4 pendientes'),
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(value: .67),
                    ]))),
                ],
              ]);
          }),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(12), color: t.fillColorScheme.warningLight,
            child: Row(children: [Icon(Icons.info_outline, color: t.textColorScheme.warning),
              const SizedBox(width: 8), const Expanded(child: Text('Aviso de ejemplo. El color acompaña al texto, no lo sustituye.'))])),
          const SizedBox(height: 16),
          // Clave propia: sin ella comparte el PageStorage del ListView (offset double vs. expandido bool).
          const ExpansionTile(key: PageStorageKey('components-expansion'),
            title: Text('Estado vacío y ayuda desplegable'), children: [
            Padding(padding: EdgeInsets.all(16), child: Text('Todavía no hay registros. Crea uno para empezar.')),
          ]),
        ]),
      ],
    );
  }
}
