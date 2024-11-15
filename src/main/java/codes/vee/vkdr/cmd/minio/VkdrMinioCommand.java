package codes.vee.vkdr.cmd.minio;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "minio", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.MINIO_BASE,
        description = "manage MinIO service",
        subcommands = {
            VkdrMinioInstallCommand.class,
            VkdrMinioRemoveCommand.class
        })
public class VkdrMinioCommand {
}
