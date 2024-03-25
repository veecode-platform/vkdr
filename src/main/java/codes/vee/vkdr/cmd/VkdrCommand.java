package codes.vee.vkdr.cmd;

import java.util.concurrent.Callable;

import codes.vee.vkdr.CommandUtils;
import codes.vee.vkdr.ScriptsExtractor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;
import picocli.CommandLine.Model.CommandSpec;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;

@Component
@Command(name = "vkdr", mixinStandardHelpOptions = true,
        version = {
                "Version 1.0",
                "Picocli " + picocli.CommandLine.VERSION,
                "JVM: ${java.version} (${java.vendor} ${java.vm.name} ${java.vm.version})",
                "OS: ${os.name} ${os.version} ${os.arch}"
        },
        description = "VKDR cli, your local friendly kubernetes",
        subcommands = {
                VkdrInfraCommand.class,
                VkdrInitCommand.class,
                VkdrNginxCommand.class,
                VkdrKongCommand.class})
public class VkdrCommand {

}
