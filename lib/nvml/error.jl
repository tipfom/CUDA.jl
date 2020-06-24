export NVMLError

struct NVMLError <: Exception
    code::nvmlReturn_t
end

Base.convert(::Type{nvmlReturn_t}, err::NVMLError) = err.code

Base.showerror(io::IO, err::NVMLError) =
    print(io, "NVMLError: ", description(err), " (code $(reinterpret(Int32, err.code)))")

description(err::NVMLError) = unsafe_string(nvmlErrorString(err))


## API call wrapper

# outlined functionality to avoid GC frame allocation
@noinline function throw_api_error(res)
    throw(NVMLError(res))
end

const initialized = Ref(false)
function initialize_api()
    if !initialized[]
        nvmlInit_v2()
        atexit() do
            nvmlShutdown()
        end
        initialized[] = true
    end
end

macro check(ex)
    quote
        res = $(esc(ex))
        if res != NVML_SUCCESS
            throw_api_error(res)
        end

        return
    end
end
