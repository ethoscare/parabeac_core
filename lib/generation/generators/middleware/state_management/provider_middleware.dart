import 'package:parabeac_core/generation/generators/middleware/middleware.dart';
import 'package:parabeac_core/generation/generators/middleware/state_management/utils/middleware_utils.dart';
import 'package:parabeac_core/generation/generators/pb_generation_manager.dart';
import 'package:parabeac_core/generation/generators/pb_variable.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy.dart/provider_file_structure_strategy.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/pb_shared_instance.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_symbol_storage.dart';
import 'package:recase/recase.dart';
import 'package:parabeac_core/generation/generators/value_objects/generator_adapter.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';

class ProviderMiddleware extends Middleware {
  final PACKAGE_NAME = 'provider';
  final PACKAGE_VERSION = '^4.3.2+3';

  static int counter = 0;

  ProviderMiddleware(PBGenerationManager generationManager)
      : super(generationManager);

  @override
  Future<PBIntermediateNode> applyMiddleware(PBIntermediateNode node) async {
    counter++;
    String watcherName;
    var managerData = node.managerData;
    var fileStrategy = node.currentContext.project.fileStructureStrategy
        as ProviderFileStructureStrategy;
    if (node is PBSharedInstanceIntermediateNode) {
      node.currentContext.project.genProjectData
          .addDependencies(PACKAGE_NAME, PACKAGE_VERSION);
      managerData.addImport('package:provider/provider.dart');
      var widgetName = node.functionCallName.camelCase;
      watcherName = node.name.snakeCase + '_notifier_${counter}';
      var watcher = PBVariable(watcherName, 'final ', true,
          'context.watch<${getName(node.functionCallName).pascalCase}>().${widgetName}');
      managerData.addMethodVariable(watcher);

      addImportToCache(node.SYMBOL_ID, getImportPath(node, fileStrategy));

      if (node.generator is! StringGeneratorAdapter) {
        node.generator = StringGeneratorAdapter(watcherName);
      }
      return node;
    }
    watcherName = getNameOfNode(node);

    var code = MiddlewareUtils.generateChangeNotifierClass(
      watcherName,
      generationManager,
      node,
    );
    fileStrategy.writeProviderModelFile(code, getName(node.name).snakeCase);

    return node;
  }

  String getImportPath(PBSharedInstanceIntermediateNode node, fileStrategy) {
    var symbolMaster =
        PBSymbolStorage().getSharedMasterNodeBySymbolID(node.SYMBOL_ID);
    return fileStrategy.GENERATED_PROJECT_PATH +
        fileStrategy.RELATIVE_MODEL_PATH +
        '${getName(symbolMaster.name).snakeCase}.dart';
  }
}
