#' R worker submitted as cluster job
#'
#' Do not call this manually, the master will do that
#'
#' @param worker_id  The ID of the worker (usually just numbered)
#' @param master     The master address (tcp://ip:port)
#' @param memlimit   Maximum memory before throwing an error
worker = function(worker_id, master, memlimit) {
    # https://github.com/krlmlr/ulimit, not on CRAN
    if (requireNamespace("ulimit", quietly=TRUE))
        ulimit::memory_limit(memlimit)

    print(master)
    print(memlimit)

    # connect to master
    context = rzmq::init.context()
    socket = rzmq::init.socket(context, "ZMQ_REQ")
    #rzmq::set.send.timeout(socket, 10000L) # milliseconds

    # send the master a ready signal
    rzmq::connect.socket(socket, master)
    rzmq::send.socket(socket, data=list(id="WORKER_UP", worker_id=worker_id))
	message("WORKER_UP to: ", master)

    # receive common data
    msg = rzmq::receive.socket(socket)
    if (!is.null(msg$redirect)) {
        data_socket = rzmq::init.socket(context, "ZMQ_REQ")
        rzmq::connect.socket(data_socket, msg$redirect)
        rzmq::send.socket(data_socket, data=list(id="WORKER_UP"))
        message("WORKER_UP to redirect: ", msg$redirect)
        msg = rzmq::receive.socket(data_socket)
    }
    fun = msg$fun
    const = msg$const
    seed = msg$seed

    print(fun)
    print(names(const))

    rzmq::send.socket(socket, data=list(id="WORKER_READY"))
    start_time = proc.time()
    counter = 0

    while(TRUE) {
        msg = rzmq::receive.socket(socket)
        message("received: ", msg$id)

        switch(msg$id,
            "DO_CHUNK" = {
                result = work_chunk(msg$chunk, fun, const, seed)
                message("completed: ", paste(rownames(msg$chunk), collapse=", "))
                names(result) = rownames(msg$chunk)
                rzmq::send.socket(socket, data=list(id="WORKER_READY", result=result))

                counter = counter + length(result)
                print(pryr::mem_used())
            },
            "WORKER_STOP" = {
                break
            }
        )
    }

    run_time = proc.time() - start_time

    message("shutting down worker")
    data = list(id="WORKER_DONE", worker_id=worker_id, time=run_time, calls=counter)
    rzmq::send.socket(socket, data)

    print(run_time)
}
