package codes.vee.vkdr.cmd.openldap;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove OpenLDAP",
        exitCodeOnExecutionException = ExitCodes.OPENLDAP_REMOVE)
public class VkdrOpenldapRemoveCommand implements Callable<Integer> {

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("openldap/remove");
    }
}
