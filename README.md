# BOSH Libvirt CPI Release

**This project is still a work in progress and not ready to deploy a BOSH director.**

This is a BOSH release for the BOSH Libvirt CPI.

## Status

The following is the current state of the different API calls when using the BOSH Libvirt CPI with the bosh-cli to create a BOSH environment.

- Stemcell management
  - create_stemcell (working but doesn't take into account the cloud properties yet)
  - delete_stemcell (needs to be tested)
- VM management
  - create_vm (can create the VM but has issues accessing it via ssh)
  - delete_vm (working)
  - has_vm (working)
  - reboot_vm (not implemented)
  - set_vm_metadata (not implemented)
  - configure_networks (not going to be implemented)
  - calculate_vm_cloud_properties (not going to be implemented)
- Disk management
  - create_disk (needs to be tested)
  - delete_disk (needs to be tested)
  - has_disk (needs to be tested)
  - attach_disk (needs to be tested)
  - detach_disk (needs to be tested)
  - get_disks (needs to be tested)
- Disk snapshots
  - snapshot_disk (not implemented)
  - delete_snapshot (not implemented)
  - current_vm_id (not implemented)

## Development

To run integration tests you will need to set up the environment variable `BOSH_LIBVIRT_STEMCELL_PATH` to point to a qemu2 stemcell in your system.

## Contributing

Issues and pull requests are more than welcome.

## License

The BOSH Libvirt CPI release is released under the [Apache2 License](/LICENSE).
