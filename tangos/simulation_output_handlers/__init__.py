"""simulation_output_handlers sub-package

This sub-package handles returning views of the original simulation data on disk for further processing.
At the moment, the views are always pynbody views, but adaptors for other frameworks could be implemented by
overriding the functionality.
"""

from __future__ import absolute_import
import os, os.path
from .. import config
import importlib
import weakref

_loaded_timesteps = {}


class SimulationOutputSetHandler(object):
    """This class handles the output from a simulation as it resides on disk.

    Subclasses provide implementations for different formats and situations.
    """

    def __init__(self, basename):
        self.basename = self.strip_slashes(basename)

    @classmethod
    def best_matching_handler(cls, basename):
        """Find the best subclass to read in the specified folder of simulation timesteps"""
        raise NotImplementedError

    def enumerate_timestep_extensions(self):
        """Yield the extension of each timestep available on disk"""
        raise NotImplementedError

    def get_properties(self):
        """Returns a dictionary of properties of the simulation"""
        raise NotImplementedError

    def get_timestep_properties(self, ts_extension):
        """Returns a dictionary of properties of the timestep"""
        raise NotImplementedError

    def enumerate_objects(self, ts_extension, object_typetag='halo'):
        """Yield halo_number, NDM, NStar, Ngas for halos in the specified timestep"""
        raise NotImplementedError

    def load_timestep(self, ts_extension, mode=None):
        """Returns an object that connects to the data for a timestep on disk -- possibly a version cached in
        memory"""
        ts_filename = self._extension_to_filename(ts_extension)
        stored_timestep = _loaded_timesteps.get(ts_filename, lambda: None)()
        if stored_timestep is not None:
            return stored_timestep
        else:
            data = self.load_timestep_without_caching(ts_extension, mode=mode)
            _loaded_timesteps[ts_filename] = weakref.ref(data)
            return data

    def load_region(self, ts_extension, region_specification, mode=None):
        """Returns an object that connects to the data for a timestep on disk, filtered using the
        specified region specification. Acceptable region specifications are output handler dependent.

        The returned object may be a sub-view of a cached in-memory timestep."""
        raise NotImplementedError

    def load_timestep_without_caching(self, ts_extension, mode=None):
        """Creates and returns an object that connects to the data for a timestep on disk"""
        raise NotImplementedError

    def load_object(self, ts_extension, halo_number, object_typetag='halo', mode=None):
        """Creates and returns an object that connects to the data for a halo on disk.

        :arg ts_extension - the timestep path (relative to the simulation basename)

        :arg halo_number - the halo number in the raw halo finder output

        :arg object_typetag - the type of halo catalogue (normally 'halo' or, for Subfind, might be 'group' to get
                                                     the top-level groups)

        :arg mode - sets a method for loading the halo, which is dependent on being implemented by the underlying
                    file manager. Current options (for the default pynbody handler) are

                     * None: load entire snapshot from disk, then return halo particles
                     * 'partial': load only the halo particles from disk
                     * 'server': use a remote server model to retrieve the particles
        """
        raise NotImplementedError

    def load_tracked_region(self, ts_extension, track_data, mode=None):
        """Creates and returns an object that connects to the on-disk data for the specified tracked region.

        :arg mode - sets a method for loading the tracked region; see load_object mode for more information"""
        raise NotImplementedError


    @classmethod
    def handler_class_name(cls):
        module = cls.__module__
        assert module.startswith(SimulationOutputSetHandler.__module__)
        submodule = module[len(SimulationOutputSetHandler.__module__)+1:]
        return submodule+"."+cls.__name__

    @staticmethod
    def strip_slashes(name):
        """Strip trailing and leading slashes from relative path"""
        if len(name) == 0: return name
        while name[0] == "/":
            name = name[1:]
            if len(name) == 0: return name
        while name[-1] == "/":
            name = name[:-1]
            if len(name) == 0: return name
        return name

    def _extension_to_filename(self, ts_extension):
        """Given the timestep extension, form the path to the actual file"""
        # Explicit str cast - pynbody seems inconsistent about how it responds to unicode filenames
        return str(os.path.join(config.base, self.basename, ts_extension))


def get_named_handler_class(handler):
    """Get a SimulationOutputSetHandler identified by the given name.

    The name is of the format submodule.ClassName

    :rtype SimulationOutputSetHandler"""
    output_module = importlib.import_module('.'+handler.split('.')[0],__name__)
    output_class = getattr(output_module, handler.split('.')[1])
    return output_class
