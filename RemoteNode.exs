defmodule RemoteNode do
    @moduledoc """
        Life cycle management for remote Elixir VMs
    """

    # Constants
    @timeout_rpc 50
    
    @doc """
        Start a remote VM node with ssh
         - Available ports are taken in consideration to take care of eventual firewalls
    """
    @spec start(String.t, String.t, String.t) :: node
    def start(name, host, program_to_run_file, secret_cookie, min_port, max_port) do
        System.cmd("ssh", [host,
                    "elixir --name #{name}@#{host} --cookie " <> secret_cookie,
                    "--erl  \'-kernel_inet_dist_listen_min " <> min_port <> "\'",
                    "--erl  \'-kernel_inet_dist_listen_max " <> max_port <> "\'",
                    "--detached --no-halt #{program_to_run_file}"])

        # Return an atom to reference this new Elixir node 
        String.to_atom(name <> "@" <> host) 
    end

    @doc """
        Stop a VM node by the fast lane
    """
    @spec stop(atom) :: no_return
    def stop(node) do
        # :rpc.block_call(node, :init, :stop, [])   like kill -15
        :rpc.call(node, :erlang, :halt, [])   # like kill -9
    end
    
    @doc """
        Kill epmd daemon from host
    """
    @spec killEpmd(String.t) :: no_return
    def killEpmd(host) do
        System.cmd("ssh", [host, "pkill epmd"])
    end

    @doc """
        Wait until Elixir VM node answers correctly
    """
    def waitRunningNode(node, module) do
        # Rpc result can be any value
        # Name of the module is the correct one !
        remoteModule = :rpc.call(node, module, :__info__, [:module], @timeout_rpc)
        if remoteModule != module, do: waitRunningNode(node, module)
    end
end
