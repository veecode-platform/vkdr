package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ScriptsExtractor;
import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@Component
@CommandLine.Command(name = "init", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 10,
        description = "Init local vkdr toolsets (downloads vkdr dependencies into `~/.vkdr/bin`)")
class VkdrInitCommand implements Callable<Integer> {
    @Override
    public Integer call() throws Exception {
        System.out.print("'init' was called...");
        ScriptsExtractor.unpackScripts();
        // runs init script
        return ShellExecutor.executeCommand("init");
    }
}
