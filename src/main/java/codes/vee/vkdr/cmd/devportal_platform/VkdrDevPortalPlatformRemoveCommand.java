package codes.vee.vkdr.cmd.devportal_platform;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@Component
@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove VeeCode DevPortal V2",
        exitCodeOnExecutionException = ExitCodes.DEVPORTAL_PLATFORM_REMOVE)
class VkdrDevPortalPlatformRemoveCommand implements Callable<Integer> {

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("devportal-platform/remove");
    }
}
