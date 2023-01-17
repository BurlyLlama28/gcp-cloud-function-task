import setuptools

REQUIRED_PACKAGES = ['some_package==2.8.3', 'another_package==0.3.0']

setuptools.setup(
    name='setup',
    version='0.0.1',
    description='install module',
    install_requires=REQUIRED_PACKAGES,
    packages=setuptools.find_packages()
)
