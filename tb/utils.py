import cocotb
from cocotb.regression import TestFactory
from functools import wraps

def test_factory(**factory_args):
    def decorator(test_func):
        @wraps(test_func)
        @cocotb.test()
        async def wrapper(dut, **kwargs):
            # Create the test factory
            factory = TestFactory(test_func)
            
            # Add options from the decorator arguments
            for arg_name, arg_values in factory_args.items():
                factory.add_option(arg_name, arg_values)
            
            # Generate and run the tests
            factory.generate_tests()
        return wrapper
    return decorator