package codes.vee.vkdr.cmd.minio;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove MinIO service",
        exitCodeOnExecutionException = ExitCodes.MINIO_REMOVE)
public class VkdrMinioRemoveCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("minio/remove");
    }
}
