package codes.vee.vkdr.cmd.kong_gw;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Kong Gateway Operator (Gateway API implementation)",
        exitCodeOnExecutionException = ExitCodes.KONG_GW_INSTALL)
public class VkdrKongGwInstallCommand implements Callable<Integer> {

    enum KongGwProfile {
        DEFAULT("default"),
        KONG("kong"),
        KONG_DISTROLESS("kong-distroless"),
        OSS("oss"),
        APIP("apip"),
        APIP_DISTROLESS("apip-distroless");

        private final String value;

        KongGwProfile(String value) {
            this.value = value;
        }

        @Override
        public String toString() {
            return value;
        }
    }

    @CommandLine.Option(names = {"--node-ports", "--node_ports", "--nodeports"},
            defaultValue = "",
            description = {
                    "NodePorts for http/https endpoints (default: '')",
                    "Example: '30000,30001' (use ports defined in 'vkdr infra start').",
                    "Using '*' means '30000,30001'.",
                    "Note: changes service type from 'LoadBalancer' to 'NodePort'."})
    private String node_ports;

    @CommandLine.Option(names = {"--profile"},
            defaultValue = "default",
            description = {
                    "Data plane image profile, must be in [${COMPLETION-CANDIDATES}] (default: default)",
                    "Shortcut for '--image'/'--tag': 'kong' and 'kong-distroless' use Kong Gateway 3.15,",
                    "'oss' uses the OSS image, 'apip' and 'apip-distroless' use the VeeCode build.",
                    "'default' keeps the formula default. Explicit '--image'/'--tag' win over the profile."})
    private KongGwProfile profile;

    @CommandLine.Option(names = {"-i","--image", "--image_name"},
            defaultValue = "",
            description = {
                    "Kong data plane image name (default: 'kong/kong-gateway')",
                    "Example: '--image kong' for the OSS image.",
                    "Overrides the image name set by '--profile'."})
    private String image_name;

    @CommandLine.Option(names = {"-t","--tag", "--image_tag"},
            defaultValue = "",
            description = {
                    "Kong data plane image tag (default: '3.14')",
                    "Append '-distroless' for the distroless variant (ex: '3.14-distroless').",
                    "Overrides the image tag set by '--profile'."})
    private String image_tag;

    @CommandLine.Option(names = {"--default-ic","--default_ingress_controller"},
            defaultValue = "false",
            description = {
                    "Makes Kong the cluster's default ingress controller (default: false)",
                    "This affects ingress objects without an 'ingressClassName' field."})
    private boolean default_ingress_controller;

    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("kong-gw/install", node_ports, image_name, image_tag,
                String.valueOf(profile), String.valueOf(default_ingress_controller));
    }
}
