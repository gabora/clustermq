#' Class for basic queuing system functions
#'
#' Provides the basic functions needed to communicate between machines
#' This should abstract most functions of rZMQ so the scheduler
#' implementations can rely on the higher level functionality
QSys = R6::R6Class("QSys",
    public = list(
        initialize = function(min_port=6000, max_port=8000) {
            private$job_num = 1
            private$zmq_context = rzmq::init.context()
            private$listen_socket(min_port, max_port)
        },

        # Provides values for job submission template
        #
        # Overwrite this in each derived class
        #
        # @param memory      The amount of memory (megabytes) to request
        # @param log_worker  Create a log file for each worker
        # @return  A list with values:
        #   job_name  : An identifier for the current job
        #   job_group : An common identifier for all jobs handled by this qsys
        #   master    : The rzmq address of the qsys instance we listen on
        #   memory    : Memory limit
        #   log_file  : File name to log workers to
        submit_job = function(memory=NULL, log_worker=FALSE) {
            # if not called from derived
            # stop("Derived class needs to overwrite submit_job()")

            if (!identical(grepl("://[^:]+:[0-9]+", private$master), TRUE))
                stop("Need to initialize QSys first")

            values = list(
                job_name = paste0("rzmq", private$port, "-", private$job_num),
                job_group = paste("/rzmq", private$node, private$port, sep="/"),
                master = private$master,
                memory = memory
            )
            if (log_worker)
                values$log_file = paste0(values$job_name, ".log")

            private$job_group = values$job_group
            private$job_num = private$job_num + 1

            values
        },

        # Send the data common to all workers, only serialize once
        send_common_data = function() {
            if (is.null(private$common_data))
                stop("Need to set_common_data() first")

            rzmq::send.socket(socket = private$socket,
                              data = private$common_data,
                              serialize = FALSE)
        },

        # Send iterated data to one worker
        send_job_data = function(...) {
            rzmq::send.socket(socket = private$socket, data = list(...))
        },

        # Read data from the socket
        receive_data = function() {
            rzmq::receive.socket(private$socket)
        },

        # Make sure all resources are closed properly
        cleanup = function(dirty=FALSE) {
        },

        # Set a remote controller instead of the local socket
        set_master = function(master) {
            private$port = sub("^tcp://[^:]+:", "", master)
            private$master = master
        }
    ),

    active = list(
        # We use the listening port as scheduler ID
        id = function() private$port,
        url = function() private$listen,
        poll = function() private$socket
    ),

    private = list(
        zmq_context = NULL,
        socket = NULL,
        port = NA,
        node = NULL,
        listen = NULL,
        master = NULL,
        job_group = NULL,
        job_num = NULL,
        common_data = NULL,

        set_common_data = function(...) {
            private$common_data = serialize(list(...), NULL)
        },

        # Create a socket and listen on a port in range
        #
        # @param fun    The function to be called
        # @param const  Constant arguments to the function call
        # @param seed   Common seed (to be used w/ job ID)
        # @return       Sets "port" and "master" attributes
        listen_socket = function(min_port, max_port=min_port, n_tries=100) {
            if (is.null(private$zmq_context))
                stop("QSys base class not initialized")

            private$socket = rzmq::init.socket(private$zmq_context, "ZMQ_REP")

            on.exit(sink())
            sink('/dev/null')
            for (i in 1:n_tries) {
                exec_socket = sample(min_port:max_port, size=1)
                addr = paste0("tcp://*:", exec_socket)
                port_found = rzmq::bind.socket(private$socket, addr)
                if (port_found)
                    break
            }
            sink()
            on.exit()

            if (!port_found)
                stop("Could not bind to port range (6000,8000) after 100 tries")

            private$node = Sys.info()[['nodename']]
            private$port = exec_socket
            private$listen = sprintf("tcp://%s:%i", private$node, exec_socket)
            private$master = private$listen
        }
    ),

    cloneable = FALSE
)
