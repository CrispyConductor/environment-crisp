# From https://github.com/ivakyb/fish_ssh_agent and modified

function __ssh_agent_acquire_lock
   set -l lockdir $HOME/.fish_ssh_agent_lock
   if mkdir $lockdir &>/dev/null
      return
   end
   sleep 1
end

function __ssh_agent_release_lock
   rm -rf $HOME/.fish_ssh_agent_lock
end

function __ssh_agent_can_connect -d "check if ssh-agent is running by trying to connect"
   if begin ssh-add -l 2>/dev/null &| grep 'has no ident' &>/dev/null; or ssh-add -l &>/dev/null; end
      return 0
   else
      return 1
   end
end

function __ssh_agent_has_process -d "check if ssh-agent is running using SSH_AGENT_PID environment variable"
   if test -z "$SSH_AGENT_PID"
      return 1
   end
   ps -ef | grep $SSH_AGENT_PID | grep -v grep | grep -q ssh-agent
   return $status
end

function __ssh_agent_is_started -d "check if ssh agent is already started"
   if __ssh_agent_can_connect
      return 0
   end

   if test -f $SSH_ENV
      fish_ssh_agent_load
      if __ssh_agent_can_connect
         return 0
      end
   end

   return 1
end

function __ssh_env_matches -d "check if the ssh-agent info in the env file matches what is currently running"
   if begin test -z "$SSH_AUTH_SOCK"; or not test -f "$SSH_ENV"; end
      return 1
   end
   set -l envsock (cat $SSH_ENV | sed 's/;/\n/g' | grep -E 'setenv +SSH_AUTH_SOCK ' | awk '{print $3}')
   if test "$envsock" = "$SSH_AUTH_SOCK"
      return 0
   else
      return 1
   end
end

function __ssh_agent_start -d "start a new ssh agent"
   echo Starting SSH agent.
   ssh-agent -c | sed 's/^echo/#echo/' > $SSH_ENV
   chmod 600 $SSH_ENV
end

function fish_ssh_agent_load
   if test -z "$SSH_ENV"
      set -xg SSH_ENV $HOME/.ssh/environment
   end
   if test -f "$SSH_ENV"
      source $SSH_ENV > /dev/null
   end
   true  # suppress errors from setenv, i.e. set -gx
end

function fish_ssh_agent --description "Start ssh-agent if not started yet, or uses already started ssh-agent."
   if test -z "$SSH_ENV"
      set -xg SSH_ENV $HOME/.ssh/environment
   end

   # don't do full connect check for every new shell for performance reasons
   if begin not status --is-login; and test -n "$SSH_AUTH_SOCK"; and __ssh_env_matches; end
      fish_ssh_agent_load
      return
   end

   __ssh_agent_acquire_lock

   if __ssh_agent_is_started
      if not __ssh_env_matches
         echo "setenv SSH_AUTH_SOCK $SSH_AUTH_SOCK" > $SSH_ENV
         chmod 600 $SSH_ENV
      end
   else
      __ssh_agent_start
      fish_ssh_agent_load
   end

   __ssh_agent_release_lock
end

