
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const workspaceDir=process.cwd();
const stagingDir=path.join(workspaceDir,'.dose-build');
const skill='C:/Users/23676/.codex/plugins/cache/openai-primary-runtime/presentations/26.1112.11217/skills/presentations';
const runtime='C:/Users/23676/.cache/codex-runtimes/codex-primary-runtime/dependencies';
const util=path.join(skill,'container_tools');
const {finalizePresentation}=await import(pathToFileURL(path.join(util,'artifact_tool_utils.mjs')).href);
const tables=[3,7,9,10];
console.log(await finalizePresentation({
 workspaceDir,candidatePath:path.join(stagingDir,'draft.pptx'),
 finalPath:path.join(workspaceDir,'汇报成品','一期剂量探索_第一次组会汇报_修订版.pptx'),
 pythonExecutable:path.join(runtime,'python','python.exe'),
 integrityValidatorPath:path.join(util,'inspect_presentation_package_integrity.py'),
 layoutValidatorPath:path.join(util,'inspect_presentation_layout_geometry.py'),
 layoutArgs:['--expected-slide-size-emu','13716000,7715250','--validate-heading-fit',...tables.flatMap(n=>['--require-native-table-slide',String(n)])],
 requiredNativeTableOwnerSlides:tables,
 fontPolicy:{basis:'design',families:['Microsoft YaHei']},
 verifyArtifactToolImport:true,
 receiptPath:path.join(stagingDir,'final-validation.json')
}));

