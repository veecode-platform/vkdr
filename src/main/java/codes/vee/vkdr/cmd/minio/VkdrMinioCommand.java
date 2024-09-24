package codes.vee.vkdr.cmd.minio;

import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.io.IOException;

@Component
@CommandLine.Command(name = "minio", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 120,
        description = "install/remove Minio storage",
        subcommands = {VkdrMinioInstallCommand.class})
public class VkdrMinioCommand {

    @CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove Minio storage",
            exitCodeOnExecutionException = 22)
    int remove() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("minio/remove");
    }

}
