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
@Command(name = "vkdr", mixinStandardHelpOptions = true, version = "version 1.0",
        description = "VKDR cli, your local friendly kubernetes",
        subcommands = {
                VkdrInfraCommand.class,
                VkdrInitCommand.class})
public class VkdrCommand {

}
