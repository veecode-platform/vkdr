package codes.vee.vkdr.cmd.keycloak;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove Keycloak",
        exitCodeOnExecutionException = ExitCodes.KEYCLOAK_REMOVE)
public class VkdrKeycloakRemoveCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("keycloak/remove");
    }
}