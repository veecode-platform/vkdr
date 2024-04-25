package codes.vee.vkdr.cmd;

import com.google.gson.Gson;
import codes.vee.vkdr.ShellExecutor;
import picocli.CommandLine;

import java.util.HashMap;
import java.util.Map;

import java.util.concurrent.Callable;
@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Kong Gateway",
        exitCodeOnExecutionException = 21)
public class VkdrKongInstallCommand implements Callable<Integer> {

    enum KongMode { dbless, standard, hybrid };
    @CommandLine.Option(names = {"-d","--domain"},
            defaultValue = "localhost",
            description = "DNS domain to use on generated ingress for Admin UI/API (default: localhost)")
    private String domain;

    @CommandLine.Option(names = {"-s","--secure","--enable_https"},
            defaultValue = "false",
            description = "enable HTTPS port too (default: false)")
    private boolean enable_https;

    @CommandLine.Option(names = {"-m","--mode"},
            defaultValue = "dbless",
            description = "Kong mode, must be in [${COMPLETION-CANDIDATES}]  (default: dbless)")
    private KongMode kong_mode;

    @CommandLine.Option(names = {"-e","--enterprise"},
            defaultValue = "false",
            description = "If 'true', Kong Gateway runs the enterprise image version. If license isn't provided Kong will run in 'free mode' (default: false)")
    private boolean enable_enterprise;

    @CommandLine.Option(names = {"-i","--image", "--image_name"},
    defaultValue = "",
    description = "Kong image name, defaults to chart default 'kong' if not 'enterprise' or to 'kong/kong-gateway' if 'enterprise' ")
    private String image_name;

    @CommandLine.Option(names = {"-t","--tag", "--image_tag"},
    defaultValue = "",
    description = "Kong image name, defaults to chart default (ex: '3.6')")
    private String image_tag;

    @CommandLine.Option(names = {"-l","--license","--license-file"},
            defaultValue = "",
            description = "Kong license file location, needed for 'enterprise' (falls back to 'free mode')")
    private String license;

    @CommandLine.Option(names = {"--env", "--environment"}, 
        description = {"Kong environment variables, can be used many times in the form '--env key=value'. ",
                        "All entries will become 'KONG_[key]=[value]', with 'key' in uppercase as per helm chart behaviour.",})
    private Map<String,String> environment = new HashMap<String,String>();

    @Override
    public Integer call() throws Exception {
        Gson gson = new Gson();
        String envJson = gson.toJson(environment);
        return ShellExecutor.executeCommand("kong/install", domain, String.valueOf(enable_https), String.valueOf(kong_mode), String.valueOf(enable_enterprise), license, image_name, image_tag, envJson);
    }
}
